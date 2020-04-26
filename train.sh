#!/bin/bash
set -e

# https://deepspeech.readthedocs.io/en/master/TRAINING.html
# https://discourse.mozilla.org/t/tutorial-how-i-trained-a-specific-french-model-to-control-my-robot/22830/2
# https://github.com/kpu/kenlm

help ()
{
    echo "syntax: $1 [options]"
    echo "options:"
    < $1 grep -v 'sed -ne' | sed -ne 's/[^#]* \([^ ]*\))[^#]*#\(.*\)/    \1\2/pg' 1>&2
    exit 1
}

dir=$(cd ${0%/*} 2>/dev/null; pwd)
tools=${dir}/tools

noupdate=false
src="voice-minimal"
while [ ! -z "$1" ]; do
    case "$1" in
        -h|--help) help "$0";;  #       help
        --noupdate) noupdate=true;;  #      skip updating env
        *) src="$1";;
    esac
    shift
done

[ -z "${src}" ] && help "$0"

if [ ! -d ${dir}/${src} ]; then
    if [ "${src}" = voice-minimal ]; then
        ${tools}/mk-voice-minimal
    else
        echo "cannot find input directory '${dir}/${src}'" 1>&2
        exit 1
    fi
fi

gen=${dir}/gen-${src}
mkdir -p ${gen}

# install missing packages on ubuntu
pkg=""
which git-lfs || pkg+="git-lfs "
if which sox ; then
    sox 2> /dev/null | grep mp3 > /dev/null || pkg+="libsox-fmt-mp3 "
else
    pkg+="sox libsox-fmt-mp3 "
fi
set -x
if [ ! -z "$pkg" ]; then
    sudo apt -y install $pkg
fi

. ./venv-enable

if [ ! -r DeepSpeech/DeepSpeech.py ]; then
    #GIT_TRACE=1 git clone --depth=1 https://github.com/mozilla/DeepSpeech
    GIT_TRACE=1 git clone --depth=1 https://github.com/d-a-v/DeepSpeech
fi
cd DeepSpeech
export PYTHONPATH+=$(pwd)/training

if ! $noupdate; then

    GIT_TRACE=1 git pull origin master

    python3 -m pip install --upgrade pip wheel setuptools
    python3 -m pip install --upgrade -e .

    cd ${dir}/${src}
    ${tools}/mktsv.sh

    cd ${dir}
    # download & build kenlm
    git clone --depth=1 https://github.com/kpu/kenlm || (cd kenlm; git pull origin master)
    mkdir -p kenlm/build
    cd kenlm/build
    cmake ..
    make

    cd ${dir}

    python3 DeepSpeech/data/lm/generate_lm.py \
        --input_txt ${src}/vocabulary.txt --output_dir . \
        --top_k 500000 --kenlm_bins ${dir}/kenlm/build/bin \
        --arpa_order 5 --max_arpa_memory "85%" --arpa_prune "0|0|1" \
        --binary_a_bits 255 --binary_q_bits 8 --binary_type trie \
        --output_dir ${gen} \
        --discount_fallback \

    python3 DeepSpeech/data/lm/generate_package.py \
        --alphabet ${tools}/alphabet.txt \
        --lm ${gen}/lm.binary \
        --vocab ${gen}/vocab-500000.txt \
        --default_alpha 0.75 \
        --default_beta 1.85 \
        --package ${gen}/scorerfile \

    cd DeepSpeech
    python3 bin/import_cv2.py --validate_label_locale ${tools}/validation.py $(pwd)/../${src}

fi

checkpoint_dir=${gen}/checkpoints
inference=${gen}/inference
mkdir -p ${checkpoint_dir} ${inference} ${inference}-lite

# Train

python3 -u DeepSpeech.py \
    --alphabet_config_path ${tools}/alphabet.txt \
    --train_files ../${src}/clips/train.csv \
    --dev_files ../${src}/clips/dev.csv \
    --test_files ../${src}/clips/test.csv \
    --export_dir "${inference}" \
    --checkpoint_dir "${checkpoint_dir}" \
    --reduce_lr_on_plateau \
    --scorer_path ${gen}/scorerfile \

#    --early_stop True \
#    --epochs 30 \
#    --report_count 100 \

# reexport for TFLite

python3 -u DeepSpeech.py \
    --alphabet_config_path ${tools}/alphabet.txt \
    --checkpoint_dir "${checkpoint_dir}" \
    --export_tflite \
    --export_dir "${inference}-lite" \
    --scorer_path ${gen}/scorerfile \

echo "done"


This repository is WIP and is setup to practice on Mozilla DeepSpeech.
----

This is a set of scripts aimed at testing / using DeepSpeech with a
relatively small set of words on a GPU-less setup (like giving orders to IoT
devices).

On an ubuntu host, a single command should install everything and start training.

By default, `tools/mk-voice-minimal` will use espeak to build artificial
spoken sentences from a set of dumb-hardcoded generated sentences, then
DeepSpeech is trained on these sentences.

`tools/mk-voice-minimal` will create a file with numbered sentences, and the
`clips/` directory with matching mp3 files.  Such tree can be "hand-made"
with your voice (or from your family - fun ahead) and used by this
repository.

This is WIP and at the time of writing, inference is not working on the
generated model :( Answers may be found in more reading/MOOCing and
experimenting.

```
$ ./train --external   # install once external tools: espeak, lame
$ ./train
```

When not given on cmdline, a voice directory is automatically created
with an artifical example. It is made by calling
```
$ ./tools/mk-voice-minimal
```
It creates:
- `voice-minimal/list.txt` containing sentences like:
  `1234 this is a dumb sentence`
- matching files: `voice-minimal/clips/1234-author.mp3` The name "`author`"
  is reported later to be the name of the speaker so one can build clips
  with several people saying and repeating a set of words in different
  sentences.

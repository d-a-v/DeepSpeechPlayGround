
words=['in','open','close','switch on','switch off','light','shutter','bedroom','kitchen','garage',]

n = 0
for i in range(0, len(words)):
    for j in range(0, len(words)):
        if j != i:
            for k in range(0, len(words)):
                if k != i and k != j:
                    print('%05d %s %s %s' % (n, words[i], words[j], words[k]))
                    n = n + 1

import sys


def main(argv):
    input=open(argv[0]).readlines()
    output=open(argv[0],'w')
    for line in input:
        line.strip()
        if "arguments=" in line:
            arguments=line.split(" ")
            line=""
            for argument in arguments:
                if "root://xrootd.unl.edu//store" in argument:
                    line=line+" "+argv[1]
                else:
                    line=line+" "+argument
        output.write("%s"%line)
    output.close()







if __name__=="__main__":
    if sys.argv[1] and sys.argv[2]:
        main((sys.argv[1],sys.argv[2]))
    else:
        print "Usage: python resubmit.py [cmd file] [input root file]"

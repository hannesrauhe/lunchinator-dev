from optparse import OptionParser
import subprocess
import logging

def getGitCommandOutput(args, path):
    call = ["git", "--no-pager", "--git-dir=" + path + "/.git", "--work-tree=" + path]
    call = call + args
     
    p = subprocess.Popen(call, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    pOut, _pErr = p.communicate()
    return pOut
    
def getLatestChangeLog(lastHash, onlyFirstLine, path):
    """Reads the commit messages since a given tag
    
    This method reads the commit messages since lastHash and returns
    a list of commit messages. Lines with bullet points will be reformatted
    to start with an asterisk, immediately followed by the message.
    
    Lines like "Merge x into y" and merge conflicts are automatically skipped.
    
    lastHash -- latest hash to NOT include
    onlyFirstLine -- For multi line commit messages, only return the description line
    """
    
    bulletpoints = set(('*', '-'))
    
    try:
        result = []
        hashes = getGitCommandOutput(["log",
                                      "--format=%h",
                                      "%s..HEAD" % lastHash], path=path)
        hashes = hashes.split('\n')
        for aHash in reversed(hashes):
            message = getGitCommandOutput(["log",
                                           "--format=%B",
                                           "%(hash)s~1..%(hash)s" % {"hash":aHash}], path)
            message = [line.strip() for line in message.strip().split('\n')]
            if len(message) == 1:
                # single line commit message
                if not message[0]:
                    continue
                if message[0][0] in bulletpoints:
                    result.append(message[0][1:].strip())
                else:
                    result.append(message[0])
            elif len(message) > 2 and len(message[1]) == 0:
                # properly formatted multi line commit
                skipSection = False
                for line in message:
                    if len(line) == 0:
                        skipSection = False
                        continue
                    if skipSection:
                        continue
                    if line.lower().startswith("merge branch"):
                        continue
                    if line.lower().startswith("conflicts:"):
                        skipSection = True
                        continue
                    
                    if line[0] in bulletpoints:
                        if not onlyFirstLine:
                            result.append("*" + line[1:].strip())
                    else:
                        result.append(line)
            else:
                logging.warning("Improperly formatted commit message for commit # " + aHash)
                # tread each line as single commit
                for line in message:
                    if line[0] in bulletpoints:
                        result.append(line[1:].strip())
                    else:
                        result.append(line)
            
        return result
    except:
        logging.exception("Error generating changelog")
        return None
        
def parse_args():
    usage = "usage: %prog [options]"
    optionParser = OptionParser(usage = usage)
    optionParser.add_option("--only-first-line",
                      default = False, dest = "onlyFirstLine", action = "store_true",
                      help = "Only return first line of multi line commit messages.")
    optionParser.add_option("--print-lines",
                      default = False, dest = "printLines", action = "store_true",
                      help = "Print lines instead of returning JSON string.")
    optionParser.add_option("--last-hash", default=None, dest="lastHash",
                      help="Last commit hash to NOT include.")
    optionParser.add_option("--path", default=None, dest="path",
                      help="Git path.")
    return optionParser.parse_args()

# ensure this is not executed when sourced from hashNSign
if __name__ == '__main__' and "changelog.py" in __file__:
    import json
    options, args = parse_args()
    
    changelog = getLatestChangeLog(options.lastHash, options.onlyFirstLine, path=options.path)
    if options.printLines:
        for line in changelog:
            print line
    else:
        print json.dumps(changelog)
    
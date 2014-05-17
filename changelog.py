from lunchinator import log_warning, log_exception
from optparse import OptionParser
import subprocess, os

# TODO use GitHandler as soon as peersandplugins is merged into master
def runGitCommand(args, path=None, quiet=True):
    """Runs a git command and returns a triple (return code, stdout output, stderr output)"""
    if path == None:
        from lunchinator import get_settings
        path = get_settings().get_main_package_path()
     
    call = ["git", "--no-pager", "--git-dir=" + path + "/.git", "--work-tree=" + path]
    call = call + args
     
    fh = subprocess.PIPE    
    if quiet:
        fh = open(os.path.devnull, "w")
    p = subprocess.Popen(call, stdout=fh, stderr=fh)
    pOut, pErr = p.communicate()
    retCode = p.returncode
    return retCode, pOut, pErr

def getGitCommandOutput(args, path=None):
    """Runs a git command and returns the stdout output."""
    _retCode, pOut, _pErr = runGitCommand(args, path, quiet=False)
    return pOut.strip()
    
def getLatestChangeLog(lastHash, onlyFirstLine, path):
    """Reads the commit messages since a given tag
    
    This method reads the commit messages since lastHash and returns
    a list that contains a string for single line commits or a list
    of strings for multi line commits. For multi line commits, the
    empty line as well as bullet points are removed.
    
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
                    result.append(message[0][1:])
                else:
                    result.append(message[0])
            elif len(message) > 2 and len(message[1]) == 0:
                # properly formatted multi line commit
                cleanedmessage = []
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
                        cleanedmessage.append(line[1:])
                    elif len(cleanedmessage) == 0:
                        # start new list
                        cleanedmessage.append(line)
                    else:
                        # no bullet point -- treat as new description line
                        if len(cleanedmessage) == 1 or onlyFirstLine:
                            result.append(cleanedmessage[0])
                        elif len(cleanedmessage) > 1:
                            result.append(cleanedmessage)
                        cleanedmessage = [line]
                        
                if len(cleanedmessage) == 1 or onlyFirstLine:
                    result.append(cleanedmessage[0])
                elif len(cleanedmessage) > 1:
                    result.append(cleanedmessage)
            else:
                log_warning("Improperly formatted commit message for commit #", aHash)
                # tread each line as single commit
                for line in message:
                    if line[0] in bulletpoints:
                        result.append(line[1:])
                    else:
                        result.append(line)
            
        return result
    except:
        log_exception("Error generating changelog")
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

if __name__ == '__main__':
    import json
    options, args = parse_args()
    
    changelog = getLatestChangeLog(options.lastHash, options.onlyFirstLine, path=options.path)
    if options.printLines:
        for line in changelog:
            print line
    else:
        print json.dumps(changelog)
    
import logging, sys, os, hashlib, shutil
import json

if os.getenv("LUNCHINATOR_GIT"):
    path = os.getenv("LUNCHINATOR_GIT")
    sys.path.insert(0, path)
else:
    sys.path.insert(0, "./lunchinator")

try:
    import lunchinator
except:
    path = os.path.abspath(sys.argv[0])
    while os.path.dirname(path) != path:
        if os.path.exists(os.path.join(path, 'lunchinator', '__init__.py')):
            sys.path.insert(0, path)
            break
        path = os.path.dirname(path)

from lunchinator.log import getCoreLogger, initializeLogger
from lunchinator.lunch_settings import lunch_settings
from lunchinator.utilities import getGPGandKey
from changelog import getLatestChangeLog

initializeLogger("./hashnsign.log")
logging.root.setLevel(logging.INFO)

if len(sys.argv) > 1 and os.path.isfile(sys.argv[1]):
    fileToSign = open(sys.argv[1], "rb")
else:
    print sys.argv
    logging.error("No file given or file does not exist")
    sys.exit(-1)

md = hashlib.md5()
md.update(fileToSign.read())
fileToSign.close()
fileHash = md.hexdigest()
logging.info("Hash is %s" % fileHash)

versionString = lunch_settings.get_singleton_instance().get_version()
commitCount = versionString.split('.')[-1]

if os.getenv("CHANGELOG_PY") and os.getenv("LAST_HASH") and os.getenv("LUNCHINATOR_GIT"):
    execfile(os.getenv("CHANGELOG_PY"))
    changeLog = getLatestChangeLog(os.getenv("LAST_HASH"), False, os.getenv("LUNCHINATOR_GIT"))
    if changeLog:
        changeLog = json.dumps(changeLog)
else:
    logging.warning("Could not generate change log.")
    changeLog = []


# create signed version.asc
versionInfo = ["Version String: " + versionString,
               "Commit Count: " + commitCount,
               "Installer Hash: " + fileHash,
               "URL: %s/%s" % (versionString, os.path.basename(fileToSign.name))]

if changeLog:
    versionInfo.append("Change Log: " + changeLog)
    
if os.getenv("LUNCHINATOR_BRANCH"):
    versionInfo.append("Branch: " + os.getenv("LUNCHINATOR_BRANCH"))

stringToSign = "\n".join(versionInfo)

gpg, keyid = getGPGandKey(secret=True)
if not gpg or not keyid:
    sys.exit(-1)

signedString = gpg.sign(stringToSign, keyid=keyid)
print stringToSign
    
working_dir = os.path.dirname(sys.argv[1])
version_file = open(os.path.join(working_dir, "latest_version.asc"), "w")
version_file.write(str(signedString))
version_file.close()

version_file = open(os.path.join(working_dir, "index.html"), "w")
version_file.write('Download lunchinator: <a href="%s/%s">Version %s</a>' % (versionString, os.path.basename(fileToSign.name), versionString))
version_file.close()

# moving files around

installer_dir = os.path.join(working_dir, versionString)
if not os.path.isdir(installer_dir):
    os.mkdir(installer_dir)

shutil.copyfile(os.path.join(working_dir, "latest_version.asc"), os.path.join(working_dir, versionString, "version.asc"))
shutil.copyfile(sys.argv[1], os.path.join(working_dir, versionString, os.path.basename(sys.argv[1])))

if os.getenv("LUNCHINATOR_UPLOAD_FTP"):
    ftp_up, _ , ftp_server = os.getenv("LUNCHINATOR_UPLOAD_FTP").partition("@")
    ftp_user, _ , ftp_pass = ftp_up.partition(":")
    ftp_file = open("commands.ftp", "w")
    ftp_file.write("OPEN %s\n"%ftp_server)
    ftp_file.write("%s\n" % ftp_user)
    ftp_file.write("%s\n" % ftp_pass)
    ftp_file.write("CD %s\n" % working_dir)
    ftp_file.write("PROMPT\n")
    ftp_file.write("PUT \"%s/latest_version.asc\"\n" % working_dir)
    ftp_file.write("PUT \"%s/index.html\"\n" % working_dir)
    ftp_file.write("mkdir \"%s\"\n" % versionString)
    ftp_file.write("CD \"%s\"\n" % versionString)
    ftp_file.write("PUT \"%s/%s/version.asc\"\n" % (working_dir, versionString))
    ftp_file.write("BINARY\n")
    ftp_file.write("PUT \"%s/%s/%s\"\n" % (working_dir, versionString, os.path.basename(sys.argv[1])))
    ftp_file.write("QUIT\n")
    ftp_file.close()
    

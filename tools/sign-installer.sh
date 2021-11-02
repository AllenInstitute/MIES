#!/bin/bash
#
# Links:
# - https://sectigo.com/faqs/detail/EV-Code-Signing-Certificates-Collection/kA01N000000brbF
# - https://www.reddit.com/r/PowerShell/comments/kj88m2/exporting_code_signing_certificates_from_an_exe/
# - https://blog.codeinside.eu/2017/11/30/signing-with-signtool-dont-forget-the-timestamp/
# - https://docs.microsoft.com/en-us/archive/blogs/ieinternals/everything-you-need-to-know-about-authenticode-code-signing
# - https://stackoverflow.com/questions/17927895/automate-extended-validation-ev-code-signing=
#
# Intallation steps:
# - Get a EV code signing certificate on a USB token (PKCS#11)
# - Install SafeNet Client Application from the vendor
# - Reboot the machine
# - Store the password and the container name in ~/.credentials/code-signing in the format "[{{token password}}]=container"
#
# Due to Microsoft Windows security features, you must not be logged in via RDP for this script to work.

# Get top level of git repo
git --version > /dev/null
if [ $? -ne 0 ]
then
  echo "Could not find git executable"
  exit 1
fi

top_level=$(git rev-parse --show-toplevel)

if [ -z "$top_level" ]
then
  echo "This is not a git repository"
  exit 1
fi

sign_tool_exe=/C/Program\ Files\ \(x86\)/Windows\ Kits/10/bin/10.0.19041.0/x64/signtool.exe

if [ ! -f "$sign_tool_exe" ]
then
  echo "Could not find signtool.exe."
  exit 1
fi

# signtool does not accept a path for the certificate
cp $top_level/tools/installer/public-key.cer public-key.cer

MSYS_NO_PATHCONV=1 "$sign_tool_exe" sign /tr http://timestamp.sectigo.com /fd sha256 /td sha256 /csp "eToken Base Cryptographic Provider" /kc $(cat ~/.credentials/code-signing) /f public-key.cer tools/installer/MIES*.exe

rm -f signing.cer

#!/bin/sh

# detect AWS Elastic Beanstalk Command Line Tool
# http://aws.amazon.com/code/6752709412171743
if [ -d ~/.aws/eb ]; then
    if [[ "$OSX" == "1" ]]; then
        export PATH=$PATH:$HOME/.aws/eb/macosx/python2.7
    fi

    if [[ "$LINUX" == "1" ]]; then
        export PATH=$PATH:~/.aws/eb/linux/python2.7
    fi
fi

FROM alpine:3.8

RUN apk --no-cache add git-svn openssh perl-git subversion python3
RUN python3 -m pip install awscli

ADD ./known_hosts /root/.ssh/
ADD ./id_rsa /root/.ssh/

ADD ./svn2git.sh .

ENTRYPOINT ["/svn2git.sh"]

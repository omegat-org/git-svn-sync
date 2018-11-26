FROM alpine:3.8

RUN apk --no-cache add git-svn openssh perl-git subversion

ADD ./known_hosts /root/.ssh/
ADD ./id_rsa /root/.ssh/

ADD ./svn2git.sh .

ENTRYPOINT ["/svn2git.sh"]

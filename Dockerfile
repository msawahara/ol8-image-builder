FROM oraclelinux:8

RUN dnf update -y && dnf install -y e2fsprogs && dnf clean all

VOLUME ["/dev", "/proc", "/sys"]

VOLUME ["/root/data"]

CMD ["/root/data/build-image.sh"]


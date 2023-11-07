FROM amd64/ubuntu

#RUN dpkg --add-architecture amd64 \
#    && apt update \
#    && apt-get install -y --no-install-recommends gcc-x86-64-linux-gnu libc6-dev-amd64-cross
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install git-all python3 python3-setuptools wget gcc-x86-64-linux-gnu build-essential g++-x86-64-linux-gnu libc6-dev-amd64-cross -y
RUN bash -c "$(wget https://gef.blah.cat/sh -O -)"

WORKDIR /
RUN git clone https://github.com/jfoote/exploitable.git

WORKDIR /exploitable
RUN python3 setup.py install

RUN echo "source /usr/local/lib/python3.10/dist-packages/exploitable-1.32-py3.10.egg/exploitable/exploitable.py" >> ~/.gdbinit

WORKDIR /
RUN wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
ENV CW_EXPLOITABLE=/usr/local/lib/python3.10/dist-packages/exploitable-1.32-py3.10.egg/exploitable/exploitable.py
ENV GOPATH=/usr/local/go

RUN go install github.com/bnagy/crashwalk/cmd/cwtriage@latest

RUN go install github.com/bnagy/crashwalk/cmd/cwdump@latest
RUN go install github.com/bnagy/crashwalk/cmd/cwfind@latest
RUN go install github.com/bnagy/afl-launch@latest

WORKDIR /
RUN git clone https://github.com/AFLplusplus/AFLplusplus
WORKDIR /AFLplusplus
RUN make distrib
RUN make install

RUN apt-get install ccache cmake make g++-multilib gdb -y \
  pkg-config coreutils python3-pexpect manpages-dev git \
  ninja-build capnproto libcapnp-dev zlib1g-dev

WORKDIR /
RUN git clone https://github.com/rr-debugger/rr.git
RUN mkdir obj 
WORKDIR /obj
RUN cmake -DCMAKE_BUILD_TYPE=Release ../rr
RUN make -j8
RUN make install
RUN sysctl kernel.perf_event_paranoid=1

ADD toFuzz /toFuzz

ENV PATH=$PATH:/AFLplusplus
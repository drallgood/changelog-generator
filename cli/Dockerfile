FROM swift:slim
WORKDIR /root
RUN apt update && apt install -y git
RUN echo "/usr/lib/swift/linux" >> /etc/ld.so.conf.d/swift.conf && ldconfig
COPY gitconfig /root/.gitconfig
COPY .build/release/changelog-generator /usr/local/bin/
ENTRYPOINT ["changelog-generator"]

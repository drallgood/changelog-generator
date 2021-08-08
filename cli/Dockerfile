FROM swift:slim
WORKDIR /root
RUN apt update && apt install -y git
COPY .build/release/changelog-generator /usr/local/bin/
COPY gitconfig /root/.gitconfig
ENTRYPOINT ["changelog-generator"]

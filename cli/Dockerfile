FROM swift:slim
WORKDIR /root
RUN apt update && apt install -y git
COPY .build .
COPY gitconfig /root/.gitconfig
ENTRYPOINT ["x86_64-unknown-linux-gnu/release/changelog-generator"]

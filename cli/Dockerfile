FROM swift:latest as builder
WORKDIR /root
COPY . .
RUN swift package clean && swift build -c release

FROM swift:slim
WORKDIR /root
COPY --from=builder /root/.build .
COPY gitconfig /root/.gitconfig
COPY known_hosts /root/.ssh/known_hosts
RUN apt update && apt install -y git
ENTRYPOINT ["x86_64-unknown-linux-gnu/release/his-changelog-generator"]

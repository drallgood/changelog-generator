FROM swift:latest as builder
WORKDIR /root
COPY . .
RUN swift package clean && swift build -c release

FROM swift:slim
WORKDIR /root
RUN apt update && apt install -y git
COPY --from=builder /root/.build .
COPY gitconfig /root/.gitconfig
ENTRYPOINT ["x86_64-unknown-linux-gnu/release/changelog-generator"]

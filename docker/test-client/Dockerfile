FROM alpine:latest

RUN apk update && apk add --no-cache bash curl wget
COPY test.sh /test.sh
RUN chmod +x /test.sh

CMD ["sleep", "infinity"]

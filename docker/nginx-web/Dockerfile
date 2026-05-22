FROM alpine:latest

RUN apk add --no-cache bash socat
COPY server.sh /server.sh
RUN chmod +x /server.sh

EXPOSE 8080

CMD ["/server.sh"]

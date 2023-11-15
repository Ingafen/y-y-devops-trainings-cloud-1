FROM golang:1.21 as build
WORKDIR /app

# Download Go modules
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
COPY tpl ./tpl
COPY watermark* ./

# Build
RUN CGO_ENABLED=0 go build -o /catgpt-app

FROM gcr.io/distroless/static-debian12:latest-amd64 as release
WORKDIR /go-app

COPY --from=build /catgpt-app /go-app/catgpt-app

EXPOSE 8080

# Run
CMD [ "/go-app/catgpt-app" ]
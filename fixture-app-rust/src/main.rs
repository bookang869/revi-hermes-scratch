mod order;

use order::{summarize, Order};
use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};

fn handle(stream: TcpStream) {
    let mut reader = BufReader::new(stream.try_clone().expect("clone stream"));
    let mut request_line = String::new();
    if reader.read_line(&mut request_line).is_err() {
        return;
    }
    let path = request_line.split_whitespace().nth(1).unwrap_or("/");

    let body = match path {
        "/healthz" => "ok".to_string(),
        "/summarize" => {
            let o = Order {
                customer: None,
                amount: 42,
            };
            summarize(&o)
        }
        _ => "not found".to_string(),
    };

    let response = format!(
        "HTTP/1.1 200 OK\r\nContent-Length: {}\r\n\r\n{}",
        body.len(),
        body
    );
    let mut stream = stream;
    let _ = stream.write_all(response.as_bytes());
}

fn main() {
    let listener = TcpListener::bind("0.0.0.0:8080").expect("bind :8080");
    for stream in listener.incoming().flatten() {
        handle(stream);
    }
}

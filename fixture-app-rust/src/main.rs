use revi_fixture_app_rust::http_util::parse_query;
use revi_fixture_app_rust::{config, discount, divide, format, inventory, items, order, stats};
use std::collections::HashMap;
use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::panic::{self, AssertUnwindSafe};

fn reason_phrase(status: u16) -> &'static str {
    match status {
        200 => "OK",
        400 => "Bad Request",
        404 => "Not Found",
        503 => "Service Unavailable",
        _ => "Unknown",
    }
}

// Route table stays identical across every fault variant of this fixture
// app -- each seeded bug lives inside exactly one handler module below, not
// here, so a fault never needs to touch main.rs.
fn route(path: &str, query: &HashMap<String, String>) -> (u16, String) {
    match path {
        "/healthz" => (200, "ok".to_string()),
        "/summarize" => order::handle(query),
        "/divide-share" => divide::handle(query),
        "/discount" => discount::handle(query),
        "/validate-order" => config::handle(query),
        "/inventory" => inventory::handle(query),
        "/format-order" => format::handle(query),
        "/items" => items::handle(query),
        "/average" => stats::handle(query),
        _ => (404, "not found".to_string()),
    }
}

fn handle(stream: TcpStream) {
    let mut reader = BufReader::new(stream.try_clone().expect("clone stream"));
    let mut request_line = String::new();
    if reader.read_line(&mut request_line).is_err() {
        return;
    }
    let request_target = request_line
        .split_whitespace()
        .nth(1)
        .unwrap_or("/")
        .to_string();
    let (path, query) = parse_query(&request_target);

    let (status, body) = route(path, &query);
    let response = format!(
        "HTTP/1.1 {} {}\r\nContent-Length: {}\r\n\r\n{}",
        status,
        reason_phrase(status),
        body.len(),
        body
    );
    let mut stream = stream;
    let _ = stream.write_all(response.as_bytes());
}

fn main() {
    let listener = TcpListener::bind("0.0.0.0:8080").expect("bind :8080");
    for stream in listener.incoming().flatten() {
        // Catch a per-request panic (e.g. a seeded divide-by-zero or
        // out-of-bounds fault) so one bad request doesn't take the whole
        // server down -- mirrors Go's net/http, which recovers panics per
        // request, so "the process keeps handling requests normally
        // afterward" (meta.json's expected_behavior) means the same thing
        // in both languages' fixtures.
        let _ = panic::catch_unwind(AssertUnwindSafe(|| handle(stream)));
    }
}

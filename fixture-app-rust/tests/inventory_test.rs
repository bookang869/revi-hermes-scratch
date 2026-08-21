// Regression test for the /inventory handler forwarding whatever status the
// downstream inventory service actually returned, instead of always
// reporting 200 regardless of the real response.
//
// This spins up a tiny fake "downstream inventory service" on localhost,
// points INVENTORY_URL at it, and asserts revi_fixture_app_rust::inventory
// relays the downstream status verbatim.

use revi_fixture_app_rust::inventory::inventory_check;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::thread;

/// Starts a background thread that accepts exactly one TCP connection,
/// reads (and discards) the request, and writes back a canned HTTP
/// response with the given status line and body. Returns the "host:port"
/// authority the fake server is listening on.
fn spawn_fake_downstream(status_line: &'static str, body: &'static str) -> String {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind fake downstream");
    let addr = listener.local_addr().expect("local_addr");

    thread::spawn(move || {
        if let Ok((mut stream, _)) = listener.accept() {
            let mut buf = [0u8; 1024];
            let _ = stream.read(&mut buf);
            let response = format!(
                "HTTP/1.0 {status_line}\r\nContent-Length: {}\r\n\r\n{body}",
                body.len()
            );
            let _ = stream.write_all(response.as_bytes());
        }
    });

    addr.to_string()
}

/// Serializes access to the shared INVENTORY_URL env var across the test
/// functions in this file, since std::env::set_var is process-global and
/// cargo test runs tests in the same binary concurrently by default.
fn with_inventory_url<T>(url: &str, f: impl FnOnce() -> T) -> T {
    use std::sync::Mutex;
    static ENV_LOCK: Mutex<()> = Mutex::new(());
    let _guard = ENV_LOCK.lock().unwrap_or_else(|p| p.into_inner());
    std::env::set_var("INVENTORY_URL", url);
    let result = f();
    std::env::remove_var("INVENTORY_URL");
    result
}

#[test]
fn forwards_downstream_non_200_status_instead_of_masking_as_200() {
    let authority = spawn_fake_downstream("404 Not Found", "sku not found");
    let base_url = format!("http://{authority}");

    let (status, body) = with_inventory_url(&base_url, || inventory_check("missing-sku"));

    assert_eq!(
        status, 404,
        "expected the real downstream 404 to be forwarded, got {status} with body {body:?}"
    );
    assert_eq!(body, "sku not found");
}

#[test]
fn forwards_downstream_500_status_instead_of_masking_as_200() {
    let authority = spawn_fake_downstream("500 Internal Server Error", "boom");
    let base_url = format!("http://{authority}");

    let (status, body) = with_inventory_url(&base_url, || inventory_check("bad-sku"));

    assert_eq!(
        status, 500,
        "expected the real downstream 500 to be forwarded, got {status} with body {body:?}"
    );
    assert_eq!(body, "boom");
}

#[test]
fn still_passes_through_a_genuine_200() {
    let authority = spawn_fake_downstream("200 OK", "in stock");
    let base_url = format!("http://{authority}");

    let (status, body) = with_inventory_url(&base_url, || inventory_check("good-sku"));

    assert_eq!(status, 200);
    assert_eq!(body, "in stock");
}

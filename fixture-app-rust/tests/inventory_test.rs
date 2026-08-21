use revi_fixture_app_rust::inventory;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::thread;

/// Spins up a minimal one-shot HTTP server that replies with the given
/// status line + body to the first connection it receives, then exits.
/// Returns the "host:port" authority string to point INVENTORY_URL at.
fn spawn_fake_downstream(status_line: &'static str, body: &'static str) -> String {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind fake downstream");
    let addr = listener.local_addr().expect("local addr");

    thread::spawn(move || {
        if let Ok((mut stream, _)) = listener.accept() {
            let mut buf = [0u8; 1024];
            let _ = stream.read(&mut buf);
            let response = format!(
                "HTTP/1.0 {}\r\nContent-Length: {}\r\n\r\n{}",
                status_line,
                body.len(),
                body
            );
            let _ = stream.write_all(response.as_bytes());
        }
    });

    addr.to_string()
}

// Both scenarios live in one #[test] fn because they mutate the shared
// process-wide INVENTORY_URL env var that inventory_check reads; running
// them as separate #[test] fns would race under cargo test's default
// parallel execution.
#[test]
fn inventory_check_relays_downstream_status_instead_of_forcing_200() {
    // Non-200 case: this is the crash this test guards against. Before the
    // fix, inventory::inventory_check hard-coded 200 on every successful
    // HTTP round trip, so a downstream 404 was relayed to callers as if the
    // lookup had succeeded.
    let authority = spawn_fake_downstream("404 Not Found", "sku not found");
    std::env::set_var("INVENTORY_URL", format!("http://{authority}"));

    let (status, body) = inventory::inventory_check("missing-sku");

    assert_eq!(
        status, 404,
        "expected the /inventory handler to relay the downstream's non-200 status, got {status} with body {body:?}"
    );
    assert_eq!(body, "sku not found");

    // 200 case: still works after the fix.
    let authority = spawn_fake_downstream("200 OK", "in stock");
    std::env::set_var("INVENTORY_URL", format!("http://{authority}"));

    let (status, body) = inventory::inventory_check("good-sku");

    assert_eq!(status, 200);
    assert_eq!(body, "in stock");
}

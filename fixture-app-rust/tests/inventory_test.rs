use revi_fixture_app_rust::inventory;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::thread;

/// Spins up a minimal downstream "inventory service" that always replies
/// with a non-200 status, then points INVENTORY_URL at it and asserts that
/// inventory_check relays the real status/body instead of forwarding it as
/// a 200 lookup.
#[test]
fn relays_non_200_downstream_status_instead_of_faking_200() {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind ephemeral port");
    let addr = listener.local_addr().expect("local addr");

    let handle = thread::spawn(move || {
        if let Ok((mut stream, _)) = listener.accept() {
            let mut buf = [0u8; 1024];
            let _ = stream.read(&mut buf);
            let body = "sku not found";
            let response = format!(
                "HTTP/1.0 404 Not Found\r\nContent-Length: {}\r\n\r\n{}",
                body.len(),
                body
            );
            let _ = stream.write_all(response.as_bytes());
        }
    });

    std::env::set_var("INVENTORY_URL", format!("http://{addr}"));

    let (status, body) = inventory::inventory_check("missing-sku");

    handle.join().expect("server thread panicked");

    assert_eq!(status, 404, "expected downstream 404 to be relayed as-is");
    assert_eq!(body, "sku not found");
}

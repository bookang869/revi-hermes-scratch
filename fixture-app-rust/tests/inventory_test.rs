use revi_fixture_app_rust::inventory::inventory_check;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::thread;

/// Spins up a tiny fake "downstream inventory service" on localhost that
/// always responds with a non-200 status, then points inventory_check at it
/// via INVENTORY_URL. Before the fix, inventory_check hard-codes 200 on any
/// successful TCP round-trip, so a 404/500 from downstream gets relayed to
/// callers as a fake "in stock" 200 -- this test catches that regression.
#[test]
fn relays_non_200_downstream_status_instead_of_faking_200() {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind fake downstream");
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

    let (status, body) = inventory_check("widget-1");

    handle.join().expect("fake downstream thread panicked");

    assert_eq!(
        status, 404,
        "expected the real downstream status (404) to be relayed, got {status} with body {body:?}"
    );
    assert_eq!(body, "sku not found");
}

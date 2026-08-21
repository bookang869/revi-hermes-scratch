use std::collections::HashMap;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::Duration;

/// Splits a raw request-target ("/path?a=1&b=2") into its path and a
/// parsed query map. The std HTTP server this fixture app is built on has
/// no framework to do this for us.
pub fn parse_query(request_target: &str) -> (&str, HashMap<String, String>) {
    match request_target.split_once('?') {
        Some((path, query)) => (path, parse_query_string(query)),
        None => (request_target, HashMap::new()),
    }
}

fn parse_query_string(query: &str) -> HashMap<String, String> {
    query
        .split('&')
        .filter(|pair| !pair.is_empty())
        .filter_map(|pair| pair.split_once('='))
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect()
}

/// Reads a query param as i64, defaulting to 0 on missing/unparsable --
/// mirrors Go's `strconv.Atoi` idiom of discarding the error and using the
/// zero value, which several of the seeded faults rely on for realism.
pub fn query_i64(query: &HashMap<String, String>, key: &str) -> i64 {
    query
        .get(key)
        .and_then(|v| v.parse::<i64>().ok())
        .unwrap_or(0)
}

pub fn query_str<'a>(query: &'a HashMap<String, String>, key: &str) -> &'a str {
    query.get(key).map(String::as_str).unwrap_or("")
}

/// Minimal single-request HTTP/1.0 GET client, used only by inventory.rs to
/// reach a downstream dependency. `base_url` is `http://host:port` (no
/// trailing path); `path` is appended as-is. No external crate: the rest
/// of this fixture app is zero-dependency by design (Cargo.toml), so this
/// stays a hand-rolled client rather than pulling in one for a single call
/// site.
pub fn http_get(base_url: &str, path: &str) -> Result<(u16, String), String> {
    let authority = base_url
        .strip_prefix("http://")
        .ok_or_else(|| format!("unsupported URL scheme: {base_url}"))?;
    let mut stream = TcpStream::connect(authority).map_err(|e| e.to_string())?;
    stream
        .set_read_timeout(Some(Duration::from_secs(2)))
        .map_err(|e| e.to_string())?;
    let host = authority.split(':').next().unwrap_or(authority);
    let request = format!("GET {path} HTTP/1.0\r\nHost: {host}\r\nConnection: close\r\n\r\n");
    stream
        .write_all(request.as_bytes())
        .map_err(|e| e.to_string())?;

    let mut raw = String::new();
    stream
        .read_to_string(&mut raw)
        .map_err(|e| e.to_string())?;

    let mut parts = raw.splitn(2, "\r\n\r\n");
    let head = parts.next().unwrap_or("");
    let body = parts.next().unwrap_or("").to_string();

    let status_line = head.lines().next().unwrap_or("");
    let status = status_line
        .split_whitespace()
        .nth(1)
        .and_then(|s| s.parse::<u16>().ok())
        .ok_or_else(|| format!("could not parse status line: {status_line}"))?;

    Ok((status, body))
}

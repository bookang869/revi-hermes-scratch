// Library target so tests/*_test.rs (Cargo's only genuinely-separate-file
// test convention -- in-crate #[cfg(test)] mods aren't a sibling file) can
// `use revi_fixture_app_rust::order::...` from outside the crate, the same
// way order.go/order.js/order.py's siblings import their fixed module
// (PLAN 6.5 follow-up, 2026-08-17).
pub mod config;
pub mod discount;
pub mod divide;
pub mod format;
pub mod http_util;
pub mod inventory;
pub mod items;
pub mod order;
pub mod stats;

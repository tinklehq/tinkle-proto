use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let proto_root = manifest_dir.join("..");
    let proto_dir = proto_root.join("tinkle");
    let proto_files = [
        "account.proto",
        "auth.proto",
        "bot_api.proto",
        "bots.proto",
        "channels.proto",
        "common.proto",
        "contacts.proto",
        "help.proto",
        "messages.proto",
        "stickers.proto",
        "users.proto",
    ];
    let protos: Vec<PathBuf> = proto_files
        .iter()
        .map(|f| proto_dir.join("v1").join(f))
        .collect();
    let proto_strs: Vec<&str> = protos.iter().map(|p| p.to_str().unwrap()).collect();
    let proto_includes = [proto_root.to_str().unwrap()];

    // tonic-build 0.13+ renamed the crate from `tonic_build` to
    // `tonic_prost_build`. The function-based API is gone; use the
    // configure().compile_protos() pattern.
    tonic_prost_build::configure()
        .build_server(false)
        .compile_protos(&proto_strs, &proto_includes)?;

    println!("cargo:rerun-if-changed={}", proto_dir.display());
    Ok(())
}

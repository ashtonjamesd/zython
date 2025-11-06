pub const Metadata = struct {
    path: []const u8,

    pub fn new(path: []const u8) Metadata {
        return Metadata{
            .path = path,
        };
    }
};

const std = @import("std");

pub fn main() !void {
    const uuid = UUIDV7.new();

    const stdout_writter = std.io.getStdOut().writer();
    try stdout_writter.print("{s}\n", .{uuid.asString()});
}

pub const UUIDV7 = struct {
    bytes: [16]u8,

    pub fn new() UUIDV7 {
        var uuid = std.mem.zeroes([16]u8);

        const time = get_time_v7();
        const t = time[0];
        const s = time[1];

        uuid[0] = @intCast((t >> 40) & 0xFF);
        uuid[1] = @intCast((t >> 32) & 0xFF);
        uuid[2] = @intCast((t >> 24) & 0xFF);
        uuid[3] = @intCast((t >> 16) & 0xFF);
        uuid[4] = @intCast((t >> 8) & 0xFF);
        uuid[5] = @intCast(t & 0xFF);

        uuid[6] = 0x70 | @as(u8, @intCast((s >> 8) & 0x0F)); // Version 7
        uuid[7] = @as(u8, @intCast(s & 0xFF));

        var prng = std.Random.DefaultPrng.init(@intCast(std.time.nanoTimestamp()));
        const random = prng.random();

        for (8..16) |i| {
            uuid[i] = random.int(u8);
        }

        uuid[8] = (uuid[8] & 0x3F) | 0x80;

        return UUIDV7{ .bytes = uuid };
    }

    pub fn asBytes(self: *const UUIDV7) [16]u8 {
        return self.bytes;
    }

    pub fn asString(self: *const UUIDV7) [36]u8 {
        var result: [36]u8 = undefined;
        format_uuid(&self.bytes, &result);
        return result;
    }

    pub fn asHexString(self: *const UUIDV7) [32]u8 {
        var result: [32]u8 = undefined;
        const hex_chars = "0123456789abcdef";

        for (self.bytes, 0..) |byte, i| {
            result[i * 2] = hex_chars[byte >> 4];
            result[i * 2 + 1] = hex_chars[byte & 0x0F];
        }

        return result;
    }

    pub fn print(self: *const UUIDV7) void {
        const uuid_str = self.asString();
        std.debug.print("UUID v7: {s}\n", .{uuid_str});
    }
};

fn get_time_v7() struct { i64, i64 } {
    const nanoPerMilli: i64 = 1_000_000;
    var lastV7time: i64 = 0;

    const nanoSeconds: i64 = @intCast(std.time.nanoTimestamp());
    const milli: i64 = @divTrunc(nanoSeconds, nanoPerMilli);
    var seq: i64 = (nanoSeconds - milli * nanoPerMilli) >> 8;
    var now: i64 = (milli << 12) + seq;

    if (now <= lastV7time) {
        now = lastV7time + 1;
        seq = now & 0xfff;
    }
    lastV7time = now;
    return .{ milli, seq };
}

fn format_uuid(uuid: *const [16]u8, output: *[36]u8) void {
    const hex_chars = "0123456789abcdef";
    var i: usize = 0;
    var o: usize = 0;

    while (i < 16) : (i += 1) {
        if (i == 4 or i == 6 or i == 8 or i == 10) {
            output[o] = '-';
            o += 1;
        }

        output[o] = hex_chars[uuid[i] >> 4];
        output[o + 1] = hex_chars[uuid[i] & 0x0F];
        o += 2;
    }
}

test "new_v7" {
    const uuid = UUIDV7.new();
    uuid.print();
}

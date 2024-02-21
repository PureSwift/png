import CRC

extension PNG
{
    /// A destination bytestream.
    ///
    /// To implement a custom data destination type, conform it to this protocol by
    /// implementing ``Destination/write(_:)``. It can
    /// then be used with the library’s core compression interfaces.
    public
    typealias BytestreamDestination = _PNGBytestreamDestination
}

/// The name of this protocol is ``PNG.BytestreamDestination``.
public
protocol _PNGBytestreamDestination
{
    /// Attempts to write the given bytes to this stream.
    ///
    /// A successful call to this function should affect the bytestream state
    /// such that subsequent calls should pick up where the last call left off.
    ///
    /// The rest of the library interprets a `nil` return value from this function
    /// as indicating a write failure.
    /// -   Parameter bytes:
    ///     The bytes to write.
    /// -   Returns:
    ///     A ``Void`` tuple, or `nil` if the write attempt failed. This
    ///     method should return `nil` even if any number of bytes less than
    ///     `bytes.count` were successfully written.
    mutating
    func write(_ buffer:[UInt8]) -> Void?
}
extension _PNGBytestreamDestination
{
    /// Emits the eight PNG signature bytes into this bytestream.
    ///
    /// This function emits the constant byte sequence
    /// `[137, 80, 78, 71, 13, 10, 26, 10]`. It will throw a
    /// ``FormattingError`` if it fails to write to the bytestream.
    ///
    /// This function is the inverse of ``Source.signature()``.
    public mutating
    func signature() throws
    {
        guard let _:Void = self.write(PNG.signature)
        else
        {
            throw PNG.FormattingError.invalidDestination
        }
    }
    /// Emits a chunk into this bytestream.
    ///
    /// This function will compute the checksum for the given chunk contents and
    /// format it with the appropriate chunk headers and footers. It will throw a
    /// ``FormattingError`` if it fails to write to the bytestream.
    ///
    /// This function is the inverse of ``Source.chunk()``.
    /// -   Parameter type:
    ///     The type identifier of the chunk to emit.
    /// -   Parameter data:
    ///     The contents of the chunk to emit. It should not include a checksum
    ///     footer, as this function computes and appends it automatically.
    ///
    ///     The default value is `[]`.
    public mutating
    func format(type:PNG.Chunk, data:[UInt8] = []) throws
    {
        let header:[UInt8] = .init(unsafeUninitializedCapacity: 8)
        {
            $0.store(data.count, asBigEndian: UInt32.self, at: 0)
            $0.store(type.name,  asBigEndian: UInt32.self, at: 4)
            $1 = 8
        }
        let footer:[UInt8] = .init(unsafeUninitializedCapacity: 4)
        {
            let crc:CRC32 = .init(hashing: header.suffix(4)).updated(with: data)
            $0.store(crc.checksum, asBigEndian: UInt32.self)
            $1 = 4
        }

        guard   let _:Void = self.write(header),
                let _:Void = self.write(data),
                let _:Void = self.write(footer)
        else
        {
            throw PNG.FormattingError.invalidDestination
        }
    }
}

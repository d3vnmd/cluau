--!strict
--[[
	BufferCodec — compact binary encoding with a bounds-checked reader for UNTRUSTED client data.
	Location: ReplicatedStorage/Shared/BufferCodec (ModuleScript)

	Why: batching many values into one `buffer` per tick cuts remote overhead (~9 B per fire) and size.
	Danger: a malicious client can send any bytes. Every read below checks bounds, caps lengths and rejects
	NaN/inf, returning nil instead of erroring the server thread.

	Writer (either side):
		local w = BufferCodec.writer(64)
		w:u8(3); w:f32(1.5); w:str("Sword", 32)
		remote:FireServer(w:finish())

	Reader (server, untrusted):
		local r = BufferCodec.reader(payload, 256) -- max accepted size
		if r == nil then return end
		local kind = r:u8(); local speed = r:f32(); local item = r:str(32)
		if kind == nil or speed == nil or item == nil or not r:done() then return end -- reject malformed
]]

local BufferCodec = {}

-- ─── writer ────────────────────────────────────────────────────────────────

local Writer = {}
Writer.__index = Writer

export type Writer = typeof(setmetatable({} :: { _buf: buffer, _pos: number }, Writer))

function BufferCodec.writer(initialSize: number?): Writer
	return setmetatable({ _buf = buffer.create(initialSize or 64), _pos = 0 }, Writer)
end

local function ensure(self: Writer, bytes: number)
	local needed = self._pos + bytes
	local size = buffer.len(self._buf)
	if needed <= size then
		return
	end
	local newSize = size
	while newSize < needed do
		newSize *= 2
	end
	local grown = buffer.create(newSize)
	buffer.copy(grown, 0, self._buf, 0, self._pos)
	self._buf = grown
end

function Writer.u8(self: Writer, value: number)
	ensure(self, 1)
	buffer.writeu8(self._buf, self._pos, value)
	self._pos += 1
end

function Writer.u16(self: Writer, value: number)
	ensure(self, 2)
	buffer.writeu16(self._buf, self._pos, value)
	self._pos += 2
end

function Writer.i16(self: Writer, value: number)
	ensure(self, 2)
	buffer.writei16(self._buf, self._pos, value)
	self._pos += 2
end

function Writer.u32(self: Writer, value: number)
	ensure(self, 4)
	buffer.writeu32(self._buf, self._pos, value)
	self._pos += 4
end

function Writer.f32(self: Writer, value: number)
	ensure(self, 4)
	buffer.writef32(self._buf, self._pos, value)
	self._pos += 4
end

--- Length-prefixed (u8) string, truncated to `maxBytes` (≤ 255).
function Writer.str(self: Writer, value: string, maxBytes: number)
	local length = math.min(#value, maxBytes, 255)
	self:u8(length)
	ensure(self, length)
	buffer.writestring(self._buf, self._pos, value, length)
	self._pos += length
end

--- Returns a right-sized copy ready to send.
function Writer.finish(self: Writer): buffer
	local out = buffer.create(self._pos)
	buffer.copy(out, 0, self._buf, 0, self._pos)
	return out
end

-- ─── reader (untrusted input) ──────────────────────────────────────────────

local Reader = {}
Reader.__index = Reader

export type Reader = typeof(setmetatable({} :: { _buf: buffer, _pos: number, _len: number, _ok: boolean }, Reader))

--- Returns nil unless `payload` is a buffer no larger than `maxBytes`.
function BufferCodec.reader(payload: unknown, maxBytes: number): Reader?
	if typeof(payload) ~= "buffer" then
		return nil
	end
	local buf = payload :: buffer
	local length = buffer.len(buf)
	if length > maxBytes then
		return nil
	end
	return setmetatable({ _buf = buf, _pos = 0, _len = length, _ok = true }, Reader)
end

local function take(self: Reader, bytes: number): number?
	if not self._ok or self._pos + bytes > self._len then
		self._ok = false
		return nil
	end
	local at = self._pos
	self._pos += bytes
	return at
end

function Reader.u8(self: Reader): number?
	local at = take(self, 1)
	return if at then buffer.readu8(self._buf, at) else nil
end

function Reader.u16(self: Reader): number?
	local at = take(self, 2)
	return if at then buffer.readu16(self._buf, at) else nil
end

function Reader.i16(self: Reader): number?
	local at = take(self, 2)
	return if at then buffer.readi16(self._buf, at) else nil
end

function Reader.u32(self: Reader): number?
	local at = take(self, 4)
	return if at then buffer.readu32(self._buf, at) else nil
end

--- Finite float only (NaN/inf rejected).
function Reader.f32(self: Reader): number?
	local at = take(self, 4)
	if at == nil then
		return nil
	end
	local value = buffer.readf32(self._buf, at)
	if value ~= value or value == math.huge or value == -math.huge then
		self._ok = false
		return nil
	end
	return value
end

--- Length-prefixed string; rejects lengths above `maxBytes` and invalid UTF-8.
function Reader.str(self: Reader, maxBytes: number): string?
	local length = self:u8()
	if length == nil or length > maxBytes then
		self._ok = false
		return nil
	end
	local at = take(self, length)
	if at == nil then
		return nil
	end
	local value = buffer.readstring(self._buf, at, length)
	if utf8.len(value) == nil then
		self._ok = false
		return nil
	end
	return value
end

--- True when every read succeeded and the whole payload was consumed (no trailing junk).
function Reader.done(self: Reader): boolean
	return self._ok and self._pos == self._len
end

-- ─── quantization helpers ──────────────────────────────────────────────────

--- Angle in radians → u8 (≈1.4° precision).
function BufferCodec.packAngle(radians: number): number
	return math.floor(((radians % (2 * math.pi)) / (2 * math.pi)) * 255 + 0.5)
end

function BufferCodec.unpackAngle(byte: number): number
	return (byte / 255) * 2 * math.pi
end

return table.freeze(BufferCodec)

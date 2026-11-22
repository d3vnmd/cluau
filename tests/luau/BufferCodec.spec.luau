--!strict
local H = require("./harness")
local BufferCodec = require("../../skills/cluau/templates/shared/BufferCodec")
local describe, it, expect = H.describe, H.it, H.expect

local function encodeSample(): buffer
	local w = BufferCodec.writer(4) -- deliberately tiny: forces growth
	w:u8(7)
	w:u16(65000)
	w:i16(-1234)
	w:u32(4000000000)
	w:f32(1.5)
	w:str("Sword", 32)
	return w:finish()
end

describe("BufferCodec", function()
	it("round-trips every type and grows the writer buffer", function()
		local payload = encodeSample()
		expect(buffer.len(payload)).toBe(1 + 2 + 2 + 4 + 4 + 1 + 5)
		local r = BufferCodec.reader(payload, 256) :: BufferCodec.Reader
		expect(r:u8()).toBe(7)
		expect(r:u16()).toBe(65000)
		expect(r:i16()).toBe(-1234)
		expect(r:u32()).toBe(4000000000)
		expect(r:f32()).toBe(1.5)
		expect(r:str(32)).toBe("Sword")
		expect(r:done()).toBe(true)
	end)

	it("rejects non-buffer payloads and oversized buffers", function()
		expect(BufferCodec.reader("hello", 256)).toBeNil()
		expect(BufferCodec.reader({}, 256)).toBeNil()
		expect(BufferCodec.reader(buffer.create(300), 256)).toBeNil()
	end)

	it("truncated payload: reads return nil and the reader stays failed", function()
		local full = encodeSample()
		local short = buffer.create(4)
		buffer.copy(short, 0, full, 0, 4)
		local r = BufferCodec.reader(short, 256) :: BufferCodec.Reader
		expect(r:u8()).toBe(7)
		expect(r:u16()).toBe(65000)
		expect(r:i16()).toBeNil() -- only 1 byte left
		expect(r:u8()).toBeNil() -- poisoned after the first failure
		expect(r:done()).toBe(false)
	end)

	it("rejects NaN and ±inf floats", function()
		for _, bad in { 0 / 0, math.huge, -math.huge } do
			local w = BufferCodec.writer()
			w:f32(bad)
			local r = BufferCodec.reader(w:finish(), 64) :: BufferCodec.Reader
			expect(r:f32()).toBeNil()
			expect(r:done()).toBe(false)
		end
	end)

	it("rejects a length prefix larger than allowed", function()
		local w = BufferCodec.writer()
		w:str(string.rep("x", 40), 255)
		local r = BufferCodec.reader(w:finish(), 256) :: BufferCodec.Reader
		expect(r:str(16)).toBeNil()
	end)

	it("rejects a length prefix that points past the end", function()
		local b = buffer.create(3)
		buffer.writeu8(b, 0, 200) -- claims 200 bytes follow
		local r = BufferCodec.reader(b, 256) :: BufferCodec.Reader
		expect(r:str(255)).toBeNil()
	end)

	it("rejects invalid UTF-8 strings", function()
		local b = buffer.create(3)
		buffer.writeu8(b, 0, 2)
		buffer.writeu8(b, 1, 255)
		buffer.writeu8(b, 2, 254)
		local r = BufferCodec.reader(b, 256) :: BufferCodec.Reader
		expect(r:str(8)).toBeNil()
	end)

	it("done() is false when trailing bytes remain (smuggled data)", function()
		local w = BufferCodec.writer()
		w:u8(1)
		w:u8(2)
		local r = BufferCodec.reader(w:finish(), 16) :: BufferCodec.Reader
		expect(r:u8()).toBe(1)
		expect(r:done()).toBe(false)
	end)

	it("writer truncates strings to maxBytes", function()
		local w = BufferCodec.writer()
		w:str("abcdefgh", 3)
		local r = BufferCodec.reader(w:finish(), 16) :: BufferCodec.Reader
		expect(r:str(8)).toBe("abc")
	end)

	it("writer(0) grows instead of looping forever (regression)", function()
		local w = BufferCodec.writer(0)
		w:u32(123)
		w:str("ok", 8)
		local r = BufferCodec.reader(w:finish(), 64) :: BufferCodec.Reader
		expect(r:u32()).toBe(123)
		expect(r:str(8)).toBe("ok")
	end)

	it("truncation never splits a multi-byte UTF-8 character (regression)", function()
		local w = BufferCodec.writer()
		w:str("Сэлэм", 5) -- 2-byte chars: 5 bytes would split the 3rd char
		local r = BufferCodec.reader(w:finish(), 64) :: BufferCodec.Reader
		expect(r:str(16)).toBe("Сэ")
		expect(r:done()).toBe(true)
	end)

	it("angle quantization stays within ~1.5°", function()
		for _, angle in { 0, 1, 2.5, math.pi, 6 } do
			local back = BufferCodec.unpackAngle(BufferCodec.packAngle(angle))
			local diff = math.abs(((back - angle + math.pi) % (2 * math.pi)) - math.pi)
			expect(diff < math.rad(1.5)).toBe(true)
		end
	end)
end)

return nil

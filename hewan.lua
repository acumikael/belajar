-- Lokasi: StarterGui > ScreenGui > CounterBox > DisplayLabel > LocalScript

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local textLabel = script.Parent

-- 1. Menunggu 'Backpack' di dalam objek Player
local backpack = player:WaitForChild("Backpack")

-- 2. Fungsi utama untuk menghitung dan update teks
local function updatePetCount()
	
	-- Tabel (dictionary) untuk menyimpan hitungan per grup umur
	-- Contoh: { [1] = 5, [2] = 3 } berarti ada 5 pet Age 1 dan 3 pet Age 2
	local ageGroups = {}
	local totalPets = 0

	-- 3. Loop semua item di dalam Backpack
	for _, item in ipairs(backpack:GetChildren()) do
		
		-- 4. Ekstrak "Age" dari nama item menggunakan string matching
		--    Pola ini mencari teks seperti "[Age 1]" atau "[Age 10]"
		local ageString = string.match(item.Name, "%[Age (%d+)%]")
		
		-- 5. Jika 'ageString' ditemukan (artinya ini adalah pet dengan format Age)
		if ageString then
			totalPets = totalPets + 1
			
			-- Konversi string (teks) umur menjadi angka
			local ageNumber = tonumber(ageString)
			
			-- Masukkan ke tabel 'ageGroups'
			if ageGroups[ageNumber] then
				-- Jika grup umur ini sudah ada, tambahkan 1
				ageGroups[ageNumber] = ageGroups[ageNumber] + 1
			else
				-- Jika ini grup umur baru, buat dengan nilai 1
				ageGroups[ageNumber] = 1
			end
		end
	end

	-- 6. Format teks yang akan ditampilkan
	--    Kita menggunakan RichText (<b>) agar judulnya tebal
	local displayText = "<b>Total Pets: " .. totalPets .. "</b>\n\n"
	
	-- 7. Urutkan grup umur agar tampil rapi (Age 1, Age 2, ...)
	local sortedAges = {}
	for ageKey in pairs(ageGroups) do
		table.insert(sortedAges, ageKey)
	end
	table.sort(sortedAges)

	-- 8. Tambahkan setiap grup umur ke teks display
	for _, age in ipairs(sortedAges) do
		local count = ageGroups[age]
		displayText = displayText .. "Age " .. age .. ": " .. count .. "\n"
	end

	-- 9. Tampilkan hasilnya di TextLabel
	textLabel.Text = displayText
end

-- --- KONEKSI EVENT ---

-- 10. Jalankan fungsi ini pertama kali saat script dimuat
updatePetCount()

-- 11. Buat 'listener' agar fungsi ini otomatis berjalan
--     setiap kali ada item (pet) DITAMBAHKAN ke Backpack
backpack.ChildAdded:Connect(updatePetCount)

-- 12. Buat 'listener' agar fungsi ini otomatis berjalan
--     setiap kali ada item (pet) DIHAPUS dari Backpack
backpack.ChildRemoved:Connect(updatePetCount)

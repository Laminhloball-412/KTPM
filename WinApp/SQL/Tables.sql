USE master
GO

IF DB_ID(N'KTPM') IS NOT NULL
BEGIN
	ALTER DATABASE KTPM SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE KTPM
END
GO

CREATE DATABASE KTPM
GO
USE KTPM
GO

/* =========================================================
   1. QUẢN TRỊ HỆ THỐNG (1.1 -> 1.30)
   ========================================================= */

-- 1.1 - 1.4: Đơn vị hành chính (huyện/xã) dùng chung bảng DonVi + phân cấp bằng HanhChinhId
CREATE TABLE HanhChinh
( Id int primary key identity
, Ten nvarchar(50)
, TrucThuocId int foreign key references HanhChinh(Id)
)
GO

CREATE TABLE TenHanhChinh
( Ten nvarchar(50)
)
GO

CREATE TABLE DonVi
( Id int primary key identity
, Ten nvarchar(100)
, Ma varchar(50)
, HanhChinhId int foreign key references HanhChinh(Id)
, TenHanhChinh nvarchar(50)
, TrucThuocId int foreign key references DonVi(Id)
, TrangThai bit
, Ext text
)
GO

-- 1.8: Định nghĩa quyền
CREATE TABLE Quyen
( Id int primary key identity
, Ten nvarchar(100)
, Ma varchar(100)
, MoTa nvarchar(max)
, TrangThai bit
, Ext text
)
GO

-- 1.7: Trạng thái người dùng
CREATE TABLE TrangThaiTaiKhoan
( Id int primary key identity
, Ten nvarchar(100)         -- Hoạt động/Khóa/Chờ duyệt...
, Ext text
)
GO

-- Hồ sơ
CREATE TABLE HoSo
( Id int primary key identity
, Ten nvarchar(100)
, SDT varchar(50)
, Email varchar(100)
, DiaChi nvarchar(255)
, NgaySinh date
, Ext text
)
GO

-- 1.5, 1.27: Tài khoản
CREATE TABLE TaiKhoan
( Ten varchar(50) primary key
, MatKhau varchar(255)
, HoSoId int foreign key references HoSo(Id)
, QuyenId int foreign key references Quyen(Id)             -- giữ đúng style mẫu (quyền “chính”)
, TrangThaiId int foreign key references TrangThaiTaiKhoan(Id)
, EmailKhoiPhuc varchar(100)
, LanDangNhapCuoi datetime
, SoLanSai int
, KhoaDen datetime
, Ext text
)
GO

-- 1.9 - 1.11: Nhóm người dùng
CREATE TABLE NhomNguoiDung
( Id int primary key identity
, Ten nvarchar(100)
, MoTa nvarchar(max)
, TrangThai bit
, NgayTao datetime default getdate()
, Ext text
)
GO

CREATE TABLE TaiKhoan_Nhom
( Id int primary key identity
, TaiKhoan varchar(50) foreign key references TaiKhoan(Ten)
, NhomId int foreign key references NhomNguoiDung(Id)
, TrangThai bit
, NgayThamGia datetime default getdate()
, Ext text
)
GO

-- 1.12 - 1.13: Phân quyền cho nhóm
CREATE TABLE Nhom_Quyen
( Id int primary key identity
, NhomId int foreign key references NhomNguoiDung(Id)
, QuyenId int foreign key references Quyen(Id)
, Ext text
)
GO

-- 1.14 - 1.15: Phân quyền cho người dùng
CREATE TABLE TaiKhoan_Quyen
( Id int primary key identity
, TaiKhoan varchar(50) foreign key references TaiKhoan(Ten)
, QuyenId int foreign key references Quyen(Id)
, Kieu nvarchar(20)          -- ALLOW / DENY
, Ext text
)
GO

-- 1.16: Menu
CREATE TABLE Menu
( Id int primary key identity
, Ten nvarchar(100)
, Url nvarchar(255)
, Icon nvarchar(100)
, ThuTu int
, TrucThuocId int foreign key references Menu(Id)
, TrangThai bit
, Ext text
)
GO

CREATE TABLE Menu_Quyen
( Id int primary key identity
, MenuId int foreign key references Menu(Id)
, QuyenId int foreign key references Quyen(Id)
, Ext text
)
GO

-- 1.17 - 1.18: Lịch sử truy cập
CREATE TABLE LichSuTruyCap
( Id int primary key identity
, TaiKhoan varchar(50) foreign key references TaiKhoan(Ten)
, ThoiGian datetime default getdate()
, HanhDong nvarchar(255)
, IPAddress varchar(50)
, UserAgent nvarchar(255)
, Ext text
)
GO

-- 1.19 - 1.20: Lịch sử tác động hệ thống
CREATE TABLE LichSuTacDong
( Id int primary key identity
, NguoiThucHien varchar(50) foreign key references TaiKhoan(Ten)
, ThoiGian datetime default getdate()
, BangTacDong nvarchar(100)
, IdBanGhi int
, LoaiTacDong nvarchar(20)     -- THEM/SUA/XOA
, NoiDungThayDoi nvarchar(max)
, Ext text
)
GO

-- 1.25, 1.29: Phiên đăng nhập (đăng nhập/đăng xuất)
CREATE TABLE PhienDangNhap
( Id int primary key identity
, TaiKhoan varchar(50) foreign key references TaiKhoan(Ten)
, ThoiGianDangNhap datetime default getdate()
, ThoiGianDangXuat datetime null
, IPAddress varchar(50)
, Token nvarchar(255)
, Ext text
)
GO

-- 1.26: Quên mật khẩu
CREATE TABLE DatLaiMatKhau
( Id int primary key identity
, TaiKhoan varchar(50) foreign key references TaiKhoan(Ten)
, MaXacNhan varchar(50)
, HetHan datetime
, DaDung bit
, NgayTao datetime default getdate()
, Ext text
)
GO

-- 1.30: Hướng dẫn sử dụng
CREATE TABLE HuongDanSuDung
( Id int primary key identity
, TieuDe nvarchar(255)
, NoiDung nvarchar(max)
, TrangThai bit
, NguoiTao varchar(50) foreign key references TaiKhoan(Ten)
, NgayTao datetime default getdate()
, Ext text
)
GO

CREATE TABLE FileHuongDanSuDung
( Id int primary key identity
, HuongDanId int foreign key references HuongDanSuDung(Id)
, TenFile nvarchar(255)
, DuongDan nvarchar(max)
, DinhDang varchar(20)
, KichThuocKB int
, NgayUpload datetime default getdate()
, Ext text
)
GO


/* =========================================================
   2. QUẢN LÝ QUY HOẠCH NƯỚC SẠCH & VSMT NÔNG THÔN (2.1 -> 2.5)
   ========================================================= */

CREATE TABLE KyQuyHoachNuocSachVSMT
( Id int primary key identity
, TenKy nvarchar(100)      -- VD: 2020-2025
, TuNam int
, DenNam int
, MoTa nvarchar(max)
, TrangThai bit
, Ext text
)
GO

CREATE TABLE QuyHoachNuocSachVSMT
( Id int primary key identity
, Ten nvarchar(255)
, DonViId int foreign key references DonVi(Id)
, KyId int foreign key references KyQuyHoachNuocSachVSMT(Id)
, TuNgay date
, DenNgay date
, CoQuanQuanLy nvarchar(255)
, MoTa nvarchar(max)
, TrangThai bit
, NguoiTao varchar(50) foreign key references TaiKhoan(Ten)
, NgayTao datetime default getdate()
, Ext text
)
GO

CREATE TABLE BaoCaoQuyHoachNuocSachVSMT
( Id int primary key identity
, QuyHoachId int foreign key references QuyHoachNuocSachVSMT(Id)
, TieuDe nvarchar(255)
, NgayBaoCao datetime default getdate()
, NoiDung nvarchar(max)
, NguoiBaoCao varchar(50) foreign key references TaiKhoan(Ten)
, Ext text
)
GO

CREATE TABLE FileBaoCaoQuyHoachNuocSachVSMT
( Id int primary key identity
, BaoCaoId int foreign key references BaoCaoQuyHoachNuocSachVSMT(Id)
, TenFile nvarchar(255)
, DuongDan nvarchar(max)
, DinhDang varchar(20)
, KichThuocKB int
, NgayUpload datetime default getdate()
, Ext text
)
GO

-- 2.5: Bản đồ quy hoạch (lưu GeoJSON / WKT)
CREATE TABLE BanDoQuyHoachNuocSachVSMT
( Id int primary key identity
, QuyHoachId int foreign key references QuyHoachNuocSachVSMT(Id)
, TenLop nvarchar(255)
, GeoJson nvarchar(max)
, MoTa nvarchar(max)
, NgayCapNhat datetime default getdate()
, Ext text
)
GO


/* =========================================================
   3. QUẢN LÝ THÔNG TIN NƯỚC SẠCH & VSMT NÔNG THÔN (3.1 -> 3.6)
   ========================================================= */

-- 3.1: Công trình cấp nước tập trung
CREATE TABLE CongTrinhTapTrung
( Id int primary key identity
, Ten nvarchar(255)
, DonViId int foreign key references DonVi(Id)
, DiaChi nvarchar(255)
, CongSuatM3Ngay float
, NguonNuoc nvarchar(255)
, TrangThai nvarchar(100)
, NamVanHanh int
, Lat float
, Lng float
, MoTa nvarchar(max)
, NguoiTao varchar(50) foreign key references TaiKhoan(Ten)
, NgayTao datetime default getdate()
, Ext text
)
GO

-- 3.3: Công trình cấp nước nhỏ lẻ
CREATE TABLE CongTrinhNhoLe
( Id int primary key identity
, Ten nvarchar(255)
, DonViId int foreign key references DonVi(Id)
, DiaChi nvarchar(255)
, ChuHo nvarchar(255)
, HinhThuc nvarchar(100)
, NguonNuoc nvarchar(255)
, TrangThai nvarchar(100)
, Lat float
, Lng float
, MoTa nvarchar(max)
, NguoiTao varchar(50) foreign key references TaiKhoan(Ten)
, NgayTao datetime default getdate()
, Ext text
)
GO

-- 3.5 - 3.6: Bản đồ phân bố + tra cứu trên bản đồ
CREATE TABLE BanDoCongTrinhNuocSach
( Id int primary key identity
, TapTrungId int null foreign key references CongTrinhTapTrung(Id)
, NhoLeId int null foreign key references CongTrinhNhoLe(Id)
, GeoJson nvarchar(max)
, GhiChu nvarchar(max)
, NgayCapNhat datetime default getdate()
, Ext text
, constraint CK_BanDoCongTrinh_OneRef check
	( (TapTrungId is not null and NhoLeId is null)
   or (TapTrungId is null and NhoLeId is not null) )
)
GO


/* =========================================================
   4. BÁO CÁO THỐNG KÊ (4.1 -> 4.7)
   ========================================================= */

-- 4.1 - 4.3: Thống kê công trình + theo thời gian + biểu đồ (dữ liệu nguồn cho biểu đồ)
CREATE TABLE ThongKeCongTrinhNuocSach
( Id int primary key identity
, DonViId int foreign key references DonVi(Id)
, ThoiGian date
, SoTapTrung int
, SoNhoLe int
, GhiChu nvarchar(max)
, NguoiLap varchar(50) foreign key references TaiKhoan(Ten)
, NgayLap datetime default getdate()
, Ext text
)
GO

-- 4.4 - 4.5: Báo cáo chỉ số nước sạch + file
CREATE TABLE ChiSoNuocSach
( Id int primary key identity
, Ten nvarchar(255)
, DonViTinh nvarchar(50)
, MoTa nvarchar(max)
, Ext text
)
GO

CREATE TABLE GiaTriChiSoNuocSach
( Id int primary key identity
, ChiSoId int foreign key references ChiSoNuocSach(Id)
, DonViId int foreign key references DonVi(Id)
, ThoiGian date
, GiaTri float
, GhiChu nvarchar(max)
, NguoiCapNhat varchar(50) foreign key references TaiKhoan(Ten)
, NgayCapNhat datetime default getdate()
, Ext text
)
GO

CREATE TABLE BaoCaoChiSoNuocSach
( Id int primary key identity
, DonViId int foreign key references DonVi(Id)
, TieuDe nvarchar(255)
, ThoiGian date
, NoiDung nvarchar(max)
, NguoiTao varchar(50) foreign key references TaiKhoan(Ten)
, NgayTao datetime default getdate()
, Ext text
)
GO

CREATE TABLE FileBaoCaoChiSoNuocSach
( Id int primary key identity
, BaoCaoId int foreign key references BaoCaoChiSoNuocSach(Id)
, TenFile nvarchar(255)
, DuongDan nvarchar(max)
, DinhDang varchar(20)
, KichThuocKB int
, NgayUpload datetime default getdate()
, Ext text
)
GO

-- 4.6 - 4.7: Báo cáo thực hiện chỉ tiêu + file
CREATE TABLE ChiTieuNuocSach
( Id int primary key identity
, Ten nvarchar(255)
, DonViTinh nvarchar(50)
, Nam int
, GiaTriMucTieu float
, MoTa nvarchar(max)
, Ext text
)
GO

CREATE TABLE ThucHienChiTieuNuocSach
( Id int primary key identity
, ChiTieuId int foreign key references ChiTieuNuocSach(Id)
, DonViId int foreign key references DonVi(Id)
, ThoiGian date
, GiaTriThucHien float
, DanhGia nvarchar(100)
, GhiChu nvarchar(max)
, NguoiCapNhat varchar(50) foreign key references TaiKhoan(Ten)
, NgayCapNhat datetime default getdate()
, Ext text
)
GO

CREATE TABLE BaoCaoThucHienChiTieuNuocSach
( Id int primary key identity
, DonViId int foreign key references DonVi(Id)
, TieuDe nvarchar(255)
, ThoiGian date
, NoiDung nvarchar(max)
, NguoiTao varchar(50) foreign key references TaiKhoan(Ten)
, NgayTao datetime default getdate()
, Ext text
)
GO

CREATE TABLE FileBaoCaoThucHienChiTieuNuocSach
( Id int primary key identity
, BaoCaoId int foreign key references BaoCaoThucHienChiTieuNuocSach(Id)
, TenFile nvarchar(255)
, DuongDan nvarchar(max)
, DinhDang varchar(20)
, KichThuocKB int
, NgayUpload datetime default getdate()
, Ext text
)
GO


/* =========================================================
   5. VĂN BẢN PHÁP LUẬT (5.1 -> 5.3)
   ========================================================= */

CREATE TABLE VanBanPhapLuatNuocSachVSMT
( Id int primary key identity
, SoVanBan nvarchar(50)
, Ten nvarchar(255)
, LoaiVanBan nvarchar(100)
, NgayBanHanh date
, CoQuanBanHanh nvarchar(255)
, TrichYeu nvarchar(max)
, HieuLucTu date
, HieuLucDen date
, Ext text
)
GO

CREATE TABLE FileVanBanPhapLuatNuocSachVSMT
( Id int primary key identity
, VanBanId int foreign key references VanBanPhapLuatNuocSachVSMT(Id)
, TenFile nvarchar(255)
, DuongDan nvarchar(max)
, DinhDang varchar(20)
, KichThuocKB int
, NgayUpload datetime default getdate()
, Ext text
)
GO


/* =========================================================
   6. CSDL CƠ SỞ CHĂN NUÔI (6.1 -> 6.9)
   ========================================================= */

-- 6.1 - 6.2: Danh mục tổ chức/cá nhân
CREATE TABLE ToChucCaNhanChanNuoi
( Id int primary key identity
, Loai nvarchar(20)          -- TOCHUC / CANHAN
, Ten nvarchar(255)
, MaSo nvarchar(50)
, SDT varchar(50)
, Email varchar(100)
, DiaChi nvarchar(max)
, Ext text
)
GO

-- Cơ sở chăn nuôi (gắn chủ sở hữu)
CREATE TABLE CoSoChanNuoi
( Id int primary key identity
, Ten nvarchar(255)
, DonViId int foreign key references DonVi(Id)
, DiaChi nvarchar(255)
, LoaiCoSo nvarchar(100)
, ChuSoHuuId int foreign key references ToChucCaNhanChanNuoi(Id)
, QuyMo nvarchar(100)
, Lat float
, Lng float
, Ext text
)
GO

-- 6.3: Điều kiện chăn nuôi
CREATE TABLE DieuKienChanNuoi
( Id int primary key identity
, CoSoId int foreign key references CoSoChanNuoi(Id)
, NgayKiemTra date
, NoiDung nvarchar(max)
, KetQua nvarchar(100)
, GhiChu nvarchar(max)
, Ext text
)
GO

-- 6.7 - 6.8: Tổ chức chứng nhận sự phù hợp
CREATE TABLE ToChucChungNhanSuPhuHop
( Id int primary key identity
, Ten nvarchar(255)
, DiaChi nvarchar(255)
, SDT varchar(50)
, Email varchar(100)
, Ext text
)
GO

-- 6.4: Giấy chứng nhận của cơ sở chăn nuôi
CREATE TABLE GiayChungNhanChanNuoi
( Id int primary key identity
, CoSoId int foreign key references CoSoChanNuoi(Id)
, ToChucChungNhanId int foreign key references ToChucChungNhanSuPhuHop(Id)
, SoGCN nvarchar(100)
, NgayCap date
, NgayHetHan date
, NoiDung nvarchar(max)
, Ext text
)
GO

-- 6.5 - 6.6: Thống kê hộ chăn nuôi nhỏ lẻ
CREATE TABLE ThongKeHoChanNuoiNhoLe
( Id int primary key identity
, DonViId int foreign key references DonVi(Id)
, Nam int
, SoHo int
, TongDan int
, GhiChu nvarchar(max)
, Ext text
)
GO

-- 6.9: Cơ sở chế biến sản phẩm chăn nuôi
CREATE TABLE CoSoCheBienSanPhamChanNuoi
( Id int primary key identity
, Ten nvarchar(255)
, DonViId int foreign key references DonVi(Id)
, DiaChi nvarchar(255)
, LoaiSanPham nvarchar(100)
, CongSuat nvarchar(100)
, Ext text
)
GO


USE KTPM;
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    ------------------------------------------------------------
    -- A) DANH MỤC HÀNH CHÍNH + ĐƠN VỊ (UPSERT)
    ------------------------------------------------------------
    -- TenHanhChinh
    INSERT INTO TenHanhChinh(Ten)
    SELECT v.Ten
    FROM (VALUES (N'Tỉnh/TP'), (N'Huyện/Quận'), (N'Xã/Phường')) v(Ten)
    WHERE NOT EXISTS (SELECT 1 FROM TenHanhChinh t WHERE t.Ten = v.Ten);

    DECLARE @HC_Tinh INT, @HC_Huyen INT, @HC_Xa INT;
    DECLARE @DV_Tinh INT, @DV_Huyen INT, @DV_Xa INT;

    -- HanhChinh (phân cấp)
    SELECT @HC_Tinh = Id FROM HanhChinh WHERE Ten = N'Tỉnh/TP' AND TrucThuocId IS NULL;
    IF @HC_Tinh IS NULL
    BEGIN
        INSERT INTO HanhChinh(Ten, TrucThuocId) VALUES (N'Tỉnh/TP', NULL);
        SET @HC_Tinh = SCOPE_IDENTITY();
    END

    SELECT @HC_Huyen = Id FROM HanhChinh WHERE Ten = N'Huyện/Quận' AND TrucThuocId = @HC_Tinh;
    IF @HC_Huyen IS NULL
    BEGIN
        INSERT INTO HanhChinh(Ten, TrucThuocId) VALUES (N'Huyện/Quận', @HC_Tinh);
        SET @HC_Huyen = SCOPE_IDENTITY();
    END

    SELECT @HC_Xa = Id FROM HanhChinh WHERE Ten = N'Xã/Phường' AND TrucThuocId = @HC_Huyen;
    IF @HC_Xa IS NULL
    BEGIN
        INSERT INTO HanhChinh(Ten, TrucThuocId) VALUES (N'Xã/Phường', @HC_Huyen);
        SET @HC_Xa = SCOPE_IDENTITY();
    END

    -- DonVi (phân cấp) - nhận diện theo Ma
    SELECT @DV_Tinh = Id FROM DonVi WHERE Ma = 'DV_TINH_DEMO';
    IF @DV_Tinh IS NULL
    BEGIN
        INSERT INTO DonVi(Ten, Ma, HanhChinhId, TenHanhChinh, TrucThuocId, TrangThai, Ext)
        VALUES (N'Tỉnh Demo', 'DV_TINH_DEMO', @HC_Tinh, N'Tỉnh/TP', NULL, 1, 'seed');
        SET @DV_Tinh = SCOPE_IDENTITY();
    END

    SELECT @DV_Huyen = Id FROM DonVi WHERE Ma = 'DV_HUYEN_DEMO';
    IF @DV_Huyen IS NULL
    BEGIN
        INSERT INTO DonVi(Ten, Ma, HanhChinhId, TenHanhChinh, TrucThuocId, TrangThai, Ext)
        VALUES (N'Huyện Demo', 'DV_HUYEN_DEMO', @HC_Huyen, N'Huyện/Quận', @DV_Tinh, 1, 'seed');
        SET @DV_Huyen = SCOPE_IDENTITY();
    END

    SELECT @DV_Xa = Id FROM DonVi WHERE Ma = 'DV_XA_DEMO';
    IF @DV_Xa IS NULL
    BEGIN
        INSERT INTO DonVi(Ten, Ma, HanhChinhId, TenHanhChinh, TrucThuocId, TrangThai, Ext)
        VALUES (N'Xã Demo', 'DV_XA_DEMO', @HC_Xa, N'Xã/Phường', @DV_Huyen, 1, 'seed');
        SET @DV_Xa = SCOPE_IDENTITY();
    END

    ------------------------------------------------------------
    -- B) QUYỀN + TRẠNG THÁI TÀI KHOẢN (UPSERT theo Ma/Ten)
    ------------------------------------------------------------
    -- Role “chính” (TaiKhoan.QuyenId trỏ vào đây)
    IF NOT EXISTS (SELECT 1 FROM Quyen WHERE Ma='ROLE_ADMIN')
        INSERT INTO Quyen(Ten, Ma, MoTa, TrangThai, Ext)
        VALUES (N'ROLE_ADMIN', 'ROLE_ADMIN', N'Quyền chính: Admin hệ thống', 1, 'role');

    IF NOT EXISTS (SELECT 1 FROM Quyen WHERE Ma='ROLE_TUNG')
        INSERT INTO Quyen(Ten, Ma, MoTa, TrangThai, Ext)
        VALUES (N'ROLE_TUNG_PLATFORM_FARM', 'ROLE_TUNG', N'Quyền chính: Nền tảng + Văn bản + Chăn nuôi', 1, 'role');

    IF NOT EXISTS (SELECT 1 FROM Quyen WHERE Ma='ROLE_MINH')
        INSERT INTO Quyen(Ten, Ma, MoTa, TrangThai, Ext)
        VALUES (N'ROLE_MINH_WATER', 'ROLE_MINH', N'Quyền chính: Nước sạch + Bản đồ + Báo cáo', 1, 'role');

    -- Permission chi tiết (Module 1/2/3/4/5/6)
    ;WITH P AS (
        SELECT * FROM (VALUES
        ('SYS_DONVI_CRUD',        N'CRUD đơn vị hành chính huyện/xã'),
        ('SYS_USER_MGMT',         N'Quản lý người dùng + trạng thái'),
        ('SYS_GROUP_MGMT',        N'Quản lý nhóm người dùng'),
        ('SYS_PERMISSION_MGMT',   N'Phân quyền nhóm/người dùng'),
        ('SYS_MENU_MGMT',         N'Quản lý menu động theo quyền'),
        ('SYS_LOG_VIEW',          N'Tra cứu log truy cập/tác động + báo cáo log'),
        ('SYS_SELF_ACCOUNT',      N'Chức năng cá nhân: đổi mật khẩu/quên mật khẩu/thông tin TK'),
        ('SYS_GUIDE_MGMT',        N'Quản lý hướng dẫn sử dụng + file'),

        ('LAW_DOC_CRUD',          N'Quản lý văn bản pháp luật'),
        ('LAW_DOC_FILE',          N'Upload/Download file văn bản'),
        ('LAW_DOC_SEARCH',        N'Tra cứu văn bản pháp luật'),

        ('FARM_OWNER_CRUD',       N'Hồ sơ tổ chức/cá nhân chăn nuôi'),
        ('FARM_BASE_CRUD',        N'Quản lý cơ sở chăn nuôi'),
        ('FARM_CONDITION',        N'Điều kiện chăn nuôi'),
        ('FARM_CERT',             N'Giấy chứng nhận chăn nuôi'),
        ('FARM_STATS',            N'Thống kê hộ nhỏ lẻ'),
        ('FARM_ORG_CERT',         N'Tổ chức chứng nhận sự phù hợp'),
        ('FARM_PROCESSING',       N'Cơ sở chế biến sản phẩm chăn nuôi'),

        ('WATER_PLAN_CRUD',       N'Quản lý kỳ quy hoạch + quy hoạch'),
        ('WATER_PLAN_REPORT',     N'Báo cáo quy hoạch + file'),
        ('WATER_PLAN_MAP',        N'Bản đồ quy hoạch (GeoJSON/WKT)'),
        ('WATER_WORKS_CRUD',      N'Quản lý công trình tập trung/nhỏ lẻ'),
        ('WATER_WORKS_MAP',       N'Bản đồ phân bố/tra cứu công trình'),

        ('WATER_STATS',           N'Thống kê công trình theo thời gian'),
        ('WATER_INDICATOR',       N'Chỉ số nước sạch + giá trị chỉ số'),
        ('WATER_TARGET',          N'Chỉ tiêu nước sạch + thực hiện chỉ tiêu'),
        ('WATER_REPORT_EXPORT',   N'Báo cáo + xuất file (Excel/PDF)')
        ) x(Ma, MoTa)
    )
    INSERT INTO Quyen(Ten, Ma, MoTa, TrangThai, Ext)
    SELECT p.Ma, p.Ma, p.MoTa, 1, 'perm'
    FROM P p
    WHERE NOT EXISTS (SELECT 1 FROM Quyen q WHERE q.Ma = p.Ma);

    -- Trạng thái tài khoản
    INSERT INTO TrangThaiTaiKhoan(Ten, Ext)
    SELECT v.Ten, v.Ext
    FROM (VALUES
        (N'Hoạt động', 'ACTIVE'),
        (N'Khóa',      'LOCKED'),
        (N'Chờ duyệt', 'PENDING')
    ) v(Ten, Ext)
    WHERE NOT EXISTS (SELECT 1 FROM TrangThaiTaiKhoan t WHERE t.Ten = v.Ten);

    ------------------------------------------------------------
    -- C) HỒ SƠ + TÀI KHOẢN (Tùng + Hoàng Minh + Admin) UPSERT
    ------------------------------------------------------------
    -- HoSo (nhận diện theo Email)
    IF NOT EXISTS (SELECT 1 FROM HoSo WHERE Email='tung.vusong@hust.edu.vn')
        INSERT INTO HoSo(Ten, SDT, Email, DiaChi, NgaySinh, Ext)
        VALUES (N'Vũ Song Tùng', '0989154248', 'tung.vusong@hust.edu.vn', N'Hà Nội', '1999-01-01', N'Phụ trách nền tảng & chăn nuôi');

    IF NOT EXISTS (SELECT 1 FROM HoSo WHERE Email='hoangminh@hust.edu.vn')
        INSERT INTO HoSo(Ten, SDT, Email, DiaChi, NgaySinh, Ext)
        VALUES (N'Hoàng Minh', '0900000002', 'hoangminh@hust.edu.vn', N'Hà Nội', '2000-01-01', N'Phụ trách nước sạch & bản đồ/báo cáo');

    IF NOT EXISTS (SELECT 1 FROM HoSo WHERE Email='admin@ktpm.local')
        INSERT INTO HoSo(Ten, SDT, Email, DiaChi, NgaySinh, Ext)
        VALUES (N'Admin Hệ thống', '0900000000', 'admin@ktpm.local', N'Hà Nội', '1990-01-01', N'Admin');

    -- TaiKhoan (nhận diện theo Ten) => KHÔNG trùng admin nữa
    IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE Ten='tung')
        INSERT INTO TaiKhoan(Ten, MatKhau, HoSoId, QuyenId, TrangThaiId, EmailKhoiPhuc, LanDangNhapCuoi, SoLanSai, KhoaDen, Ext)
        VALUES(
            'tung','1234',
            (SELECT TOP 1 Id FROM HoSo WHERE Email='tung.vusong@hust.edu.vn'),
            (SELECT TOP 1 Id FROM Quyen WHERE Ma='ROLE_TUNG'),
            (SELECT TOP 1 Id FROM TrangThaiTaiKhoan WHERE Ten=N'Hoạt động'),
            'tung.vusong@hust.edu.vn', NULL, 0, NULL, 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE Ten='hoangminh')
        INSERT INTO TaiKhoan(Ten, MatKhau, HoSoId, QuyenId, TrangThaiId, EmailKhoiPhuc, LanDangNhapCuoi, SoLanSai, KhoaDen, Ext)
        VALUES(
            'hoangminh','1234',
            (SELECT TOP 1 Id FROM HoSo WHERE Email='hoangminh@hust.edu.vn'),
            (SELECT TOP 1 Id FROM Quyen WHERE Ma='ROLE_MINH'),
            (SELECT TOP 1 Id FROM TrangThaiTaiKhoan WHERE Ten=N'Hoạt động'),
            'hoangminh@hust.edu.vn', NULL, 0, NULL, 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE Ten='admin')
        INSERT INTO TaiKhoan(Ten, MatKhau, HoSoId, QuyenId, TrangThaiId, EmailKhoiPhuc, LanDangNhapCuoi, SoLanSai, KhoaDen, Ext)
        VALUES(
            'admin','admin123',
            (SELECT TOP 1 Id FROM HoSo WHERE Email='admin@ktpm.local'),
            (SELECT TOP 1 Id FROM Quyen WHERE Ma='ROLE_ADMIN'),
            (SELECT TOP 1 Id FROM TrangThaiTaiKhoan WHERE Ten=N'Hoạt động'),
            'admin@ktpm.local', NULL, 0, NULL, 'seed'
        );

    ------------------------------------------------------------
    -- D) NHÓM NGƯỜI DÙNG + GÁN NHÓM + QUYỀN (theo phân công)
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM NhomNguoiDung WHERE Ten=N'NHOM_ADMIN')
        INSERT INTO NhomNguoiDung(Ten, MoTa, TrangThai, Ext)
        VALUES (N'NHOM_ADMIN', N'Nhóm quản trị hệ thống', 1, 'seed');

    IF NOT EXISTS (SELECT 1 FROM NhomNguoiDung WHERE Ten=N'NHOM_TUNG_PLATFORM_FARM')
        INSERT INTO NhomNguoiDung(Ten, MoTa, TrangThai, Ext)
        VALUES (N'NHOM_TUNG_PLATFORM_FARM', N'Tùng phụ trách: Module 1 + 5 + 6', 1, 'seed');

    IF NOT EXISTS (SELECT 1 FROM NhomNguoiDung WHERE Ten=N'NHOM_MINH_WATER_REPORT_MAP')
        INSERT INTO NhomNguoiDung(Ten, MoTa, TrangThai, Ext)
        VALUES (N'NHOM_MINH_WATER_REPORT_MAP', N'Hoàng Minh phụ trách: Module 2 + 3 + 4', 1, 'seed');

    -- Gán user vào nhóm (không trùng)
    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan_Nhom 
        WHERE TaiKhoan='admin' AND NhomId=(SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_ADMIN')
    )
        INSERT INTO TaiKhoan_Nhom(TaiKhoan, NhomId, TrangThai, Ext)
        VALUES ('admin', (SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_ADMIN'), 1, 'seed');

    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan_Nhom 
        WHERE TaiKhoan='tung' AND NhomId=(SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_TUNG_PLATFORM_FARM')
    )
        INSERT INTO TaiKhoan_Nhom(TaiKhoan, NhomId, TrangThai, Ext)
        VALUES ('tung', (SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_TUNG_PLATFORM_FARM'), 1, 'seed');

    IF NOT EXISTS (
        SELECT 1 FROM TaiKhoan_Nhom 
        WHERE TaiKhoan='hoangminh' AND NhomId=(SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_MINH_WATER_REPORT_MAP')
    )
        INSERT INTO TaiKhoan_Nhom(TaiKhoan, NhomId, TrangThai, Ext)
        VALUES ('hoangminh', (SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_MINH_WATER_REPORT_MAP'), 1, 'seed');

    -- Quyền cho nhóm Admin: tất cả permission (trừ role)
    INSERT INTO Nhom_Quyen(NhomId, QuyenId, Ext)
    SELECT (SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_ADMIN'),
           Q.Id, 'seed'
    FROM Quyen Q
    WHERE Q.Ma NOT LIKE 'ROLE_%'
      AND NOT EXISTS (
          SELECT 1 FROM Nhom_Quyen nq
          WHERE nq.NhomId=(SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_ADMIN') AND nq.QuyenId=Q.Id
      );

    -- Quyền cho nhóm Tùng: SYS + LAW + FARM
    INSERT INTO Nhom_Quyen(NhomId, QuyenId, Ext)
    SELECT (SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_TUNG_PLATFORM_FARM'),
           Q.Id, 'seed'
    FROM Quyen Q
    WHERE Q.Ma IN (
        'SYS_DONVI_CRUD','SYS_USER_MGMT','SYS_GROUP_MGMT','SYS_PERMISSION_MGMT','SYS_MENU_MGMT','SYS_LOG_VIEW','SYS_SELF_ACCOUNT','SYS_GUIDE_MGMT',
        'LAW_DOC_CRUD','LAW_DOC_FILE','LAW_DOC_SEARCH',
        'FARM_OWNER_CRUD','FARM_BASE_CRUD','FARM_CONDITION','FARM_CERT','FARM_STATS','FARM_ORG_CERT','FARM_PROCESSING'
    )
      AND NOT EXISTS (
          SELECT 1 FROM Nhom_Quyen nq
          WHERE nq.NhomId=(SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_TUNG_PLATFORM_FARM') AND nq.QuyenId=Q.Id
      );

    -- Quyền cho nhóm Hoàng Minh: WATER PLAN + WORKS + MAP + REPORT/CHART
    INSERT INTO Nhom_Quyen(NhomId, QuyenId, Ext)
    SELECT (SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_MINH_WATER_REPORT_MAP'),
           Q.Id, 'seed'
    FROM Quyen Q
    WHERE Q.Ma IN (
        'WATER_PLAN_CRUD','WATER_PLAN_REPORT','WATER_PLAN_MAP',
        'WATER_WORKS_CRUD','WATER_WORKS_MAP',
        'WATER_STATS','WATER_INDICATOR','WATER_TARGET','WATER_REPORT_EXPORT'
    )
      AND NOT EXISTS (
          SELECT 1 FROM Nhom_Quyen nq
          WHERE nq.NhomId=(SELECT Id FROM NhomNguoiDung WHERE Ten=N'NHOM_MINH_WATER_REPORT_MAP') AND nq.QuyenId=Q.Id
      );

    ------------------------------------------------------------
    -- E) MENU ĐỘNG + MENU_QUYEN (UPSERT theo Url)
    ------------------------------------------------------------
    DECLARE @M_SYS INT, @M_LAW INT, @M_FARM INT, @M_WATER INT, @M_REPORT INT, @M_MAP INT;

    IF NOT EXISTS (SELECT 1 FROM Menu WHERE Url=N'/sys')
        INSERT INTO Menu(Ten, Url, Icon, ThuTu, TrucThuocId, TrangThai, Ext)
        VALUES (N'Quản trị hệ thống', N'/sys', N'settings', 1, NULL, 1, 'seed');
    SELECT @M_SYS = Id FROM Menu WHERE Url=N'/sys';

    IF NOT EXISTS (SELECT 1 FROM Menu WHERE Url=N'/law')
        INSERT INTO Menu(Ten, Url, Icon, ThuTu, TrucThuocId, TrangThai, Ext)
        VALUES (N'Văn bản pháp luật', N'/law', N'book', 2, NULL, 1, 'seed');
    SELECT @M_LAW = Id FROM Menu WHERE Url=N'/law';

    IF NOT EXISTS (SELECT 1 FROM Menu WHERE Url=N'/farm')
        INSERT INTO Menu(Ten, Url, Icon, ThuTu, TrucThuocId, TrangThai, Ext)
        VALUES (N'CSDL Chăn nuôi', N'/farm', N'home', 3, NULL, 1, 'seed');
    SELECT @M_FARM = Id FROM Menu WHERE Url=N'/farm';

    IF NOT EXISTS (SELECT 1 FROM Menu WHERE Url=N'/water')
        INSERT INTO Menu(Ten, Url, Icon, ThuTu, TrucThuocId, TrangThai, Ext)
        VALUES (N'Nước sạch & Quy hoạch', N'/water', N'droplet', 4, NULL, 1, 'seed');
    SELECT @M_WATER = Id FROM Menu WHERE Url=N'/water';

    IF NOT EXISTS (SELECT 1 FROM Menu WHERE Url=N'/map')
        INSERT INTO Menu(Ten, Url, Icon, ThuTu, TrucThuocId, TrangThai, Ext)
        VALUES (N'Bản đồ (GIS)', N'/map', N'map', 5, NULL, 1, 'seed');
    SELECT @M_MAP = Id FROM Menu WHERE Url=N'/map';

    IF NOT EXISTS (SELECT 1 FROM Menu WHERE Url=N'/report')
        INSERT INTO Menu(Ten, Url, Icon, ThuTu, TrucThuocId, TrangThai, Ext)
        VALUES (N'Báo cáo/Thống kê', N'/report', N'chart', 6, NULL, 1, 'seed');
    SELECT @M_REPORT = Id FROM Menu WHERE Url=N'/report';

    -- menu con helper (insert nếu chưa có Url)
    ;WITH MN AS (
        SELECT * FROM (VALUES
        (N'Đơn vị hành chính', N'/sys/donvi', N'building', 1, @M_SYS),
        (N'Người dùng',       N'/sys/users', N'users',    2, @M_SYS),
        (N'Nhóm & phân quyền',N'/sys/roles', N'shield',   3, @M_SYS),
        (N'Menu',             N'/sys/menu',  N'list',     4, @M_SYS),
        (N'Log hệ thống',      N'/sys/logs',  N'log',      5, @M_SYS),
        (N'Hướng dẫn sử dụng', N'/sys/guide', N'help',     6, @M_SYS),

        (N'Danh sách văn bản', N'/law/docs',  N'file',     1, @M_LAW),
        (N'Tra cứu văn bản',   N'/law/search',N'search',   2, @M_LAW),

        (N'Tổ chức/Cá nhân',   N'/farm/owners',    N'id',       1, @M_FARM),
        (N'Cơ sở chăn nuôi',   N'/farm/bases',     N'warehouse',2, @M_FARM),
        (N'Điều kiện & GCN',   N'/farm/cert',      N'check',    3, @M_FARM),
        (N'Thống kê hộ nhỏ lẻ',N'/farm/stats',     N'bar',      4, @M_FARM),
        (N'Tổ chức chứng nhận',N'/farm/cert-org',  N'badge',    5, @M_FARM),
        (N'Cơ sở chế biến',    N'/farm/processing',N'factory',  6, @M_FARM),

        (N'Kỳ quy hoạch',      N'/water/ky',        N'calendar', 1, @M_WATER),
        (N'Quy hoạch',         N'/water/plan',      N'layers',   2, @M_WATER),
        (N'Báo cáo quy hoạch', N'/water/plan-report',N'file-text',3, @M_WATER),
        (N'Công trình tập trung',N'/water/taptrung', N'droplet', 4, @M_WATER),
        (N'Công trình nhỏ lẻ', N'/water/nhele',     N'droplet',  5, @M_WATER),

        (N'Bản đồ quy hoạch',  N'/map/quyhoach',    N'map',      1, @M_MAP),
        (N'Bản đồ công trình', N'/map/congtrinh',   N'map-pin',  2, @M_MAP),

        (N'Thống kê công trình',N'/report/thongke', N'chart',    1, @M_REPORT),
        (N'Chỉ số nước sạch',   N'/report/chiso',   N'percent',  2, @M_REPORT),
        (N'Chỉ tiêu & thực hiện',N'/report/chitieu',N'target',   3, @M_REPORT),
        (N'Xuất báo cáo',       N'/report/export',  N'download', 4, @M_REPORT)
        ) x(Ten, Url, Icon, ThuTu, ParentId)
    )
    INSERT INTO Menu(Ten, Url, Icon, ThuTu, TrucThuocId, TrangThai, Ext)
    SELECT mn.Ten, mn.Url, mn.Icon, mn.ThuTu, mn.ParentId, 1, 'seed'
    FROM MN mn
    WHERE NOT EXISTS (SELECT 1 FROM Menu m WHERE m.Url = mn.Url);

    -- Map menu -> permission (không trùng)
    INSERT INTO Menu_Quyen(MenuId, QuyenId, Ext)
    SELECT M.Id, Q.Id, 'seed'
    FROM Menu M
    JOIN Quyen Q ON
    (
      (M.Url = N'/sys/donvi' AND Q.Ma='SYS_DONVI_CRUD') OR
      (M.Url = N'/sys/users' AND Q.Ma='SYS_USER_MGMT') OR
      (M.Url = N'/sys/roles' AND Q.Ma IN ('SYS_GROUP_MGMT','SYS_PERMISSION_MGMT')) OR
      (M.Url = N'/sys/menu' AND Q.Ma='SYS_MENU_MGMT') OR
      (M.Url = N'/sys/logs' AND Q.Ma='SYS_LOG_VIEW') OR
      (M.Url = N'/sys/guide' AND Q.Ma='SYS_GUIDE_MGMT') OR

      (M.Url IN (N'/law/docs',N'/law/search') AND Q.Ma IN ('LAW_DOC_CRUD','LAW_DOC_FILE','LAW_DOC_SEARCH')) OR

      (M.Url = N'/farm/owners' AND Q.Ma='FARM_OWNER_CRUD') OR
      (M.Url = N'/farm/bases' AND Q.Ma='FARM_BASE_CRUD') OR
      (M.Url = N'/farm/cert' AND Q.Ma IN ('FARM_CONDITION','FARM_CERT')) OR
      (M.Url = N'/farm/stats' AND Q.Ma='FARM_STATS') OR
      (M.Url = N'/farm/cert-org' AND Q.Ma='FARM_ORG_CERT') OR
      (M.Url = N'/farm/processing' AND Q.Ma='FARM_PROCESSING') OR

      (M.Url IN (N'/water/ky',N'/water/plan') AND Q.Ma='WATER_PLAN_CRUD') OR
      (M.Url = N'/water/plan-report' AND Q.Ma='WATER_PLAN_REPORT') OR
      (M.Url IN (N'/water/taptrung',N'/water/nhele') AND Q.Ma='WATER_WORKS_CRUD') OR
      (M.Url = N'/map/quyhoach' AND Q.Ma='WATER_PLAN_MAP') OR
      (M.Url = N'/map/congtrinh' AND Q.Ma='WATER_WORKS_MAP') OR

      (M.Url = N'/report/thongke' AND Q.Ma='WATER_STATS') OR
      (M.Url = N'/report/chiso' AND Q.Ma='WATER_INDICATOR') OR
      (M.Url = N'/report/chitieu' AND Q.Ma='WATER_TARGET') OR
      (M.Url = N'/report/export' AND Q.Ma='WATER_REPORT_EXPORT')
    )
    WHERE NOT EXISTS (
        SELECT 1 FROM Menu_Quyen mq WHERE mq.MenuId=M.Id AND mq.QuyenId=Q.Id
    );

    ------------------------------------------------------------
    -- F) MODULE 5: VĂN BẢN PHÁP LUẬT + FILE (Tùng) UPSERT
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM VanBanPhapLuatNuocSachVSMT WHERE SoVanBan=N'01/2024/QĐ-UBND')
        INSERT INTO VanBanPhapLuatNuocSachVSMT
        (SoVanBan, Ten, LoaiVanBan, NgayBanHanh, CoQuanBanHanh, TrichYeu, HieuLucTu, HieuLucDen, Ext)
        VALUES
        (N'01/2024/QĐ-UBND', N'Quy định quản lý nước sạch nông thôn', N'Quyết định', '2024-02-01', N'UBND Tỉnh Demo',
         N'Quy định quản lý, vận hành và kiểm tra chất lượng nước sạch nông thôn', '2024-03-01', NULL, 'seed');

    IF NOT EXISTS (SELECT 1 FROM VanBanPhapLuatNuocSachVSMT WHERE SoVanBan=N'05/2025/TT-BNN')
        INSERT INTO VanBanPhapLuatNuocSachVSMT
        (SoVanBan, Ten, LoaiVanBan, NgayBanHanh, CoQuanBanHanh, TrichYeu, HieuLucTu, HieuLucDen, Ext)
        VALUES
        (N'05/2025/TT-BNN', N'Hướng dẫn chỉ tiêu nước sạch & VSMT', N'Thông tư', '2025-05-10', N'Bộ NN&PTNT',
         N'Chuẩn hóa tiêu chí, biểu mẫu báo cáo', '2025-06-01', NULL, 'seed');

    INSERT INTO FileVanBanPhapLuatNuocSachVSMT(VanBanId, TenFile, DuongDan, DinhDang, KichThuocKB, Ext)
    SELECT vb.Id, f.TenFile, f.DuongDan, f.DinhDang, f.KichThuocKB, 'seed'
    FROM (
        VALUES
        (N'01/2024/QĐ-UBND', N'01_2024_QDUBND.pdf', N'/uploads/law/01_2024_QDUBND.pdf', 'pdf', 520),
        (N'05/2025/TT-BNN',  N'05_2025_TTBNN.pdf',  N'/uploads/law/05_2025_TTBNN.pdf',  'pdf', 610)
    ) f(SoVB, TenFile, DuongDan, DinhDang, KichThuocKB)
    JOIN VanBanPhapLuatNuocSachVSMT vb ON vb.SoVanBan = f.SoVB
    WHERE NOT EXISTS (SELECT 1 FROM FileVanBanPhapLuatNuocSachVSMT x WHERE x.DuongDan = f.DuongDan);

    ------------------------------------------------------------
    -- G) MODULE 6: CHĂN NUÔI (Tùng) UPSERT
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM ToChucCaNhanChanNuoi WHERE MaSo=N'CN001')
        INSERT INTO ToChucCaNhanChanNuoi(Loai, Ten, MaSo, SDT, Email, DiaChi, Ext)
        VALUES (N'CANHAN', N'Hộ ông Nguyễn Văn A', N'CN001', '0911111111', 'a@demo.local', N'Xã Demo', 'seed');

    IF NOT EXISTS (SELECT 1 FROM ToChucCaNhanChanNuoi WHERE MaSo=N'TC001')
        INSERT INTO ToChucCaNhanChanNuoi(Loai, Ten, MaSo, SDT, Email, DiaChi, Ext)
        VALUES (N'TOCHUC', N'Công ty Chăn nuôi B', N'TC001', '0922222222', 'b@demo.local', N'Huyện Demo', 'seed');

    IF NOT EXISTS (SELECT 1 FROM ToChucChungNhanSuPhuHop WHERE Ten=N'Tổ chức chứng nhận DemoCert')
        INSERT INTO ToChucChungNhanSuPhuHop(Ten, DiaChi, SDT, Email, Ext)
        VALUES (N'Tổ chức chứng nhận DemoCert', N'Tỉnh Demo', '0933333333', 'democert@demo.local', 'seed');

    IF NOT EXISTS (SELECT 1 FROM CoSoChanNuoi WHERE Ten=N'Trang trại gà - Hộ A')
        INSERT INTO CoSoChanNuoi(Ten, DonViId, DiaChi, LoaiCoSo, ChuSoHuuId, QuyMo, Lat, Lng, Ext)
        VALUES (
            N'Trang trại gà - Hộ A', @DV_Xa, N'Thôn 2 - Xã Demo', N'Gia cầm',
            (SELECT TOP 1 Id FROM ToChucCaNhanChanNuoi WHERE MaSo=N'CN001'),
            N'Nhỏ', 21.002, 105.802, 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM CoSoChanNuoi WHERE Ten=N'Trang trại lợn - Công ty B')
        INSERT INTO CoSoChanNuoi(Ten, DonViId, DiaChi, LoaiCoSo, ChuSoHuuId, QuyMo, Lat, Lng, Ext)
        VALUES (
            N'Trang trại lợn - Công ty B', @DV_Huyen, N'Thị trấn Demo', N'Heo',
            (SELECT TOP 1 Id FROM ToChucCaNhanChanNuoi WHERE MaSo=N'TC001'),
            N'Vừa', 21.005, 105.805, 'seed'
        );

    INSERT INTO DieuKienChanNuoi(CoSoId, NgayKiemTra, NoiDung, KetQua, GhiChu, Ext)
    SELECT cs.Id, v.NgayKiemTra, v.NoiDung, v.KetQua, v.GhiChu, 'seed'
    FROM (
        VALUES
        (N'Trang trại gà - Hộ A', N'2025-12-01', N'Kiểm tra vệ sinh chuồng trại, xử lý chất thải', N'Đạt', N'Đạt yêu cầu'),
        (N'Trang trại lợn - Công ty B', N'2025-12-02', N'Kiểm tra khoảng cách an toàn, hồ sơ thú y', N'Đạt', N'Đạt yêu cầu')
    ) v(TenCoSo, NgayKiemTra, NoiDung, KetQua, GhiChu)
    JOIN CoSoChanNuoi cs ON cs.Ten = v.TenCoSo
    WHERE NOT EXISTS (
        SELECT 1 FROM DieuKienChanNuoi d
        WHERE d.CoSoId = cs.Id AND d.NgayKiemTra = v.NgayKiemTra
    );

    IF NOT EXISTS (SELECT 1 FROM GiayChungNhanChanNuoi WHERE SoGCN=N'GCN-2025-0001')
        INSERT INTO GiayChungNhanChanNuoi(CoSoId, ToChucChungNhanId, SoGCN, NgayCap, NgayHetHan, NoiDung, Ext)
        VALUES (
            (SELECT TOP 1 Id FROM CoSoChanNuoi WHERE Ten=N'Trang trại gà - Hộ A'),
            (SELECT TOP 1 Id FROM ToChucChungNhanSuPhuHop WHERE Ten=N'Tổ chức chứng nhận DemoCert'),
            N'GCN-2025-0001', '2025-12-05', '2028-12-05', N'Giấy chứng nhận đạt điều kiện chăn nuôi', 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM ThongKeHoChanNuoiNhoLe WHERE DonViId=@DV_Xa AND Nam=2025)
        INSERT INTO ThongKeHoChanNuoiNhoLe(DonViId, Nam, SoHo, TongDan, GhiChu, Ext)
        VALUES (@DV_Xa, 2025, 128, 3400, N'Thống kê hộ nhỏ lẻ (demo)', 'seed');

    IF NOT EXISTS (SELECT 1 FROM CoSoCheBienSanPhamChanNuoi WHERE Ten=N'Cơ sở chế biến DemoFood')
        INSERT INTO CoSoCheBienSanPhamChanNuoi(Ten, DonViId, DiaChi, LoaiSanPham, CongSuat, Ext)
        VALUES (N'Cơ sở chế biến DemoFood', @DV_Huyen, N'Thị trấn Demo', N'Thịt/Trứng', N'2 tấn/ngày', 'seed');

    ------------------------------------------------------------
    -- H) MODULE 2-3: QUY HOẠCH + CÔNG TRÌNH + MAP (Hoàng Minh)
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM KyQuyHoachNuocSachVSMT WHERE TenKy=N'2021-2025')
        INSERT INTO KyQuyHoachNuocSachVSMT(TenKy, TuNam, DenNam, MoTa, TrangThai, Ext)
        VALUES (N'2021-2025', 2021, 2025, N'Kỳ quy hoạch 2021-2025', 1, 'seed');

    IF NOT EXISTS (SELECT 1 FROM KyQuyHoachNuocSachVSMT WHERE TenKy=N'2024-2026')
        INSERT INTO KyQuyHoachNuocSachVSMT(TenKy, TuNam, DenNam, MoTa, TrangThai, Ext)
        VALUES (N'2024-2026', 2024, 2026, N'Kỳ quy hoạch 2024-2026', 1, 'seed');

    IF NOT EXISTS (SELECT 1 FROM QuyHoachNuocSachVSMT WHERE Ten=N'Quy hoạch nước sạch Huyện Demo')
        INSERT INTO QuyHoachNuocSachVSMT(Ten, DonViId, KyId, TuNgay, DenNgay, CoQuanQuanLy, MoTa, TrangThai, NguoiTao, Ext)
        VALUES (
            N'Quy hoạch nước sạch Huyện Demo', @DV_Huyen,
            (SELECT TOP 1 Id FROM KyQuyHoachNuocSachVSMT WHERE TenKy=N'2021-2025'),
            '2021-01-01','2025-12-31', N'UBND Huyện Demo', N'Quy hoạch tổng thể nước sạch & VSMT', 1, 'hoangminh', 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM QuyHoachNuocSachVSMT WHERE Ten=N'Quy hoạch nước sạch Xã Demo')
        INSERT INTO QuyHoachNuocSachVSMT(Ten, DonViId, KyId, TuNgay, DenNgay, CoQuanQuanLy, MoTa, TrangThai, NguoiTao, Ext)
        VALUES (
            N'Quy hoạch nước sạch Xã Demo', @DV_Xa,
            (SELECT TOP 1 Id FROM KyQuyHoachNuocSachVSMT WHERE TenKy=N'2024-2026'),
            '2024-01-01','2026-12-31', N'UBND Xã Demo', N'Quy hoạch chi tiết theo khu vực', 1, 'hoangminh', 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM BaoCaoQuyHoachNuocSachVSMT WHERE TieuDe=N'Báo cáo quy hoạch - lần 1')
        INSERT INTO BaoCaoQuyHoachNuocSachVSMT(QuyHoachId, TieuDe, NoiDung, NguoiBaoCao, Ext)
        VALUES(
            (SELECT TOP 1 Id FROM QuyHoachNuocSachVSMT WHERE Ten=N'Quy hoạch nước sạch Huyện Demo'),
            N'Báo cáo quy hoạch - lần 1', N'Tổng hợp hiện trạng, đề xuất phương án sơ bộ', 'hoangminh', 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM FileBaoCaoQuyHoachNuocSachVSMT WHERE DuongDan=N'/uploads/quyhoach/bc_quyhoach_lan1.pdf')
        INSERT INTO FileBaoCaoQuyHoachNuocSachVSMT(BaoCaoId, TenFile, DuongDan, DinhDang, KichThuocKB, Ext)
        VALUES(
            (SELECT TOP 1 Id FROM BaoCaoQuyHoachNuocSachVSMT WHERE TieuDe=N'Báo cáo quy hoạch - lần 1'),
            N'bc_quyhoach_lan1.pdf', N'/uploads/quyhoach/bc_quyhoach_lan1.pdf', 'pdf', 420, 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM BanDoQuyHoachNuocSachVSMT WHERE TenLop=N'RanhGioiQuyHoach')
        INSERT INTO BanDoQuyHoachNuocSachVSMT(QuyHoachId, TenLop, GeoJson, MoTa, Ext)
        VALUES(
            (SELECT TOP 1 Id FROM QuyHoachNuocSachVSMT WHERE Ten=N'Quy hoạch nước sạch Huyện Demo'),
            N'RanhGioiQuyHoach', N'{"type":"FeatureCollection","features":[]}', N'Layer demo GeoJSON', 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM CongTrinhTapTrung WHERE Ten=N'Nhà máy nước tập trung Huyện Demo')
        INSERT INTO CongTrinhTapTrung(Ten, DonViId, DiaChi, CongSuatM3Ngay, NguonNuoc, TrangThai, NamVanHanh, Lat, Lng, MoTa, NguoiTao, Ext)
        VALUES(
            N'Nhà máy nước tập trung Huyện Demo', @DV_Huyen, N'Thị trấn Demo', 1500, N'Nước mặt', N'Hoạt động', 2018,
            21.0001, 105.8001, N'Công trình chính', 'hoangminh', 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM CongTrinhNhoLe WHERE Ten=N'Giếng khoan hộ dân cụm 1')
        INSERT INTO CongTrinhNhoLe(Ten, DonViId, DiaChi, ChuHo, HinhThuc, NguonNuoc, TrangThai, Lat, Lng, MoTa, NguoiTao, Ext)
        VALUES(
            N'Giếng khoan hộ dân cụm 1', @DV_Xa, N'Thôn 1 - Xã Demo', N'Nguyễn Văn C', N'Giếng khoan', N'Nước ngầm',
            N'Đang sử dụng', 21.0020, 105.8020, N'Nước nhỏ lẻ', 'hoangminh', 'seed'
        );

    -- Bản đồ công trình: 2 dòng (taptrung / nho le)
    IF NOT EXISTS (SELECT 1 FROM BanDoCongTrinhNuocSach WHERE GhiChu=N'Pin demo công trình tập trung')
        INSERT INTO BanDoCongTrinhNuocSach(TapTrungId, NhoLeId, GeoJson, GhiChu, Ext)
        VALUES(
            (SELECT TOP 1 Id FROM CongTrinhTapTrung WHERE Ten=N'Nhà máy nước tập trung Huyện Demo'),
            NULL, N'{"type":"FeatureCollection","features":[]}', N'Pin demo công trình tập trung', 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM BanDoCongTrinhNuocSach WHERE GhiChu=N'Pin demo công trình nhỏ lẻ')
        INSERT INTO BanDoCongTrinhNuocSach(TapTrungId, NhoLeId, GeoJson, GhiChu, Ext)
        VALUES(
            NULL,
            (SELECT TOP 1 Id FROM CongTrinhNhoLe WHERE Ten=N'Giếng khoan hộ dân cụm 1'),
            N'{"type":"FeatureCollection","features":[]}', N'Pin demo công trình nhỏ lẻ', 'seed'
        );

    ------------------------------------------------------------
    -- I) MODULE 4: THỐNG KÊ + CHỈ SỐ + CHỈ TIÊU + FILE
    ------------------------------------------------------------
    -- ThongKeCongTrinhNuocSach (3 tháng)
    INSERT INTO ThongKeCongTrinhNuocSach(DonViId, ThoiGian, SoTapTrung, SoNhoLe, GhiChu, NguoiLap, Ext)
    SELECT @DV_Huyen, v.ThoiGian, v.SoTapTrung, v.SoNhoLe, v.GhiChu, 'hoangminh', 'seed'
    FROM (VALUES
        (CONVERT(date,'2025-10-01'), 1, 3, N'Dữ liệu demo tháng 10'),
        (CONVERT(date,'2025-11-01'), 1, 4, N'Dữ liệu demo tháng 11'),
        (CONVERT(date,'2025-12-01'), 1, 4, N'Dữ liệu demo tháng 12')
    ) v(ThoiGian, SoTapTrung, SoNhoLe, GhiChu)
    WHERE NOT EXISTS (
        SELECT 1 FROM ThongKeCongTrinhNuocSach t
        WHERE t.DonViId=@DV_Huyen AND t.ThoiGian=v.ThoiGian
    );

    IF NOT EXISTS (SELECT 1 FROM ChiSoNuocSach WHERE Ten=N'Tỷ lệ hộ dùng nước sạch')
        INSERT INTO ChiSoNuocSach(Ten, DonViTinh, MoTa, Ext)
        VALUES (N'Tỷ lệ hộ dùng nước sạch', N'%', N'Phần trăm hộ dân tiếp cận nước sạch đạt chuẩn', 'seed');

    IF NOT EXISTS (SELECT 1 FROM ChiSoNuocSach WHERE Ten=N'Tỷ lệ công trình hoạt động')
        INSERT INTO ChiSoNuocSach(Ten, DonViTinh, MoTa, Ext)
        VALUES (N'Tỷ lệ công trình hoạt động', N'%', N'Phần trăm công trình đang hoạt động', 'seed');

    INSERT INTO GiaTriChiSoNuocSach(ChiSoId, DonViId, ThoiGian, GiaTri, GhiChu, NguoiCapNhat, Ext)
    SELECT cs.Id, @DV_Huyen, CONVERT(date,'2025-12-01'), v.GiaTri, N'Demo', 'hoangminh', 'seed'
    FROM (VALUES
        (N'Tỷ lệ hộ dùng nước sạch', 92.5),
        (N'Tỷ lệ công trình hoạt động', 85.0)
    ) v(TenChiSo, GiaTri)
    JOIN ChiSoNuocSach cs ON cs.Ten = v.TenChiSo
    WHERE NOT EXISTS (
        SELECT 1 FROM GiaTriChiSoNuocSach g
        WHERE g.ChiSoId=cs.Id AND g.DonViId=@DV_Huyen AND g.ThoiGian=CONVERT(date,'2025-12-01')
    );

    IF NOT EXISTS (SELECT 1 FROM BaoCaoChiSoNuocSach WHERE TieuDe=N'Báo cáo chỉ số nước sạch Q4/2025')
        INSERT INTO BaoCaoChiSoNuocSach(DonViId, TieuDe, ThoiGian, NoiDung, NguoiTao, Ext)
        VALUES (@DV_Huyen, N'Báo cáo chỉ số nước sạch Q4/2025', '2025-12-01', N'Tổng hợp chỉ số và nhận xét', 'hoangminh', 'seed');

    IF NOT EXISTS (SELECT 1 FROM FileBaoCaoChiSoNuocSach WHERE DuongDan=N'/exports/chiso_2025Q4.xlsx')
        INSERT INTO FileBaoCaoChiSoNuocSach(BaoCaoId, TenFile, DuongDan, DinhDang, KichThuocKB, Ext)
        VALUES(
            (SELECT TOP 1 Id FROM BaoCaoChiSoNuocSach WHERE TieuDe=N'Báo cáo chỉ số nước sạch Q4/2025'),
            N'bc_chiso_2025Q4.xlsx', N'/exports/chiso_2025Q4.xlsx', 'xlsx', 180, 'seed'
        );

    IF NOT EXISTS (SELECT 1 FROM ChiTieuNuocSach WHERE Ten=N'Chỉ tiêu tỷ lệ hộ dùng nước sạch' AND Nam=2025)
        INSERT INTO ChiTieuNuocSach(Ten, DonViTinh, Nam, GiaTriMucTieu, MoTa, Ext)
        VALUES (N'Chỉ tiêu tỷ lệ hộ dùng nước sạch', N'%', 2025, 95.0, N'Mục tiêu năm 2025', 'seed');

    INSERT INTO ThucHienChiTieuNuocSach(ChiTieuId, DonViId, ThoiGian, GiaTriThucHien, DanhGia, GhiChu, NguoiCapNhat, Ext)
    SELECT ct.Id, @DV_Huyen, CONVERT(date,'2025-12-01'), 92.5, N'Chưa đạt', N'Demo', 'hoangminh', 'seed'
    FROM ChiTieuNuocSach ct
    WHERE ct.Nam=2025 AND ct.Ten=N'Chỉ tiêu tỷ lệ hộ dùng nước sạch'
      AND NOT EXISTS (
        SELECT 1 FROM ThucHienChiTieuNuocSach th
        WHERE th.ChiTieuId=ct.Id AND th.DonViId=@DV_Huyen AND th.ThoiGian=CONVERT(date,'2025-12-01')
      );

    IF NOT EXISTS (SELECT 1 FROM BaoCaoThucHienChiTieuNuocSach WHERE TieuDe=N'Báo cáo thực hiện chỉ tiêu Q4/2025')
        INSERT INTO BaoCaoThucHienChiTieuNuocSach(DonViId, TieuDe, ThoiGian, NoiDung, NguoiTao, Ext)
        VALUES (@DV_Huyen, N'Báo cáo thực hiện chỉ tiêu Q4/2025', '2025-12-01', N'Tổng hợp thực hiện chỉ tiêu', 'hoangminh', 'seed');

    IF NOT EXISTS (SELECT 1 FROM FileBaoCaoThucHienChiTieuNuocSach WHERE DuongDan=N'/exports/chitieu_2025Q4.pdf')
        INSERT INTO FileBaoCaoThucHienChiTieuNuocSach(BaoCaoId, TenFile, DuongDan, DinhDang, KichThuocKB, Ext)
        VALUES(
            (SELECT TOP 1 Id FROM BaoCaoThucHienChiTieuNuocSach WHERE TieuDe=N'Báo cáo thực hiện chỉ tiêu Q4/2025'),
            N'bc_chitieu_2025Q4.pdf', N'/exports/chitieu_2025Q4.pdf', 'pdf', 260, 'seed'
        );

    ------------------------------------------------------------
    -- J) HƯỚNG DẪN SỬ DỤNG + FILE
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HuongDanSuDung WHERE TieuDe=N'Hướng dẫn sử dụng hệ thống')
        INSERT INTO HuongDanSuDung(TieuDe, NoiDung, TrangThai, NguoiTao, Ext)
        VALUES (N'Hướng dẫn sử dụng hệ thống', N'1) Đăng nhập  2) Quản lý dữ liệu  3) Xuất báo cáo', 1, 'tung', 'seed');

    IF NOT EXISTS (SELECT 1 FROM FileHuongDanSuDung WHERE DuongDan=N'/uploads/guide/huongdan.pdf')
        INSERT INTO FileHuongDanSuDung(HuongDanId, TenFile, DuongDan, DinhDang, KichThuocKB, Ext)
        VALUES(
            (SELECT TOP 1 Id FROM HuongDanSuDung WHERE TieuDe=N'Hướng dẫn sử dụng hệ thống'),
            N'huongdan.pdf', N'/uploads/guide/huongdan.pdf', 'pdf', 300, 'seed'
        );

    ------------------------------------------------------------
    -- K) LOG TRUY CẬP + LOG TÁC ĐỘNG (demo, không trùng theo key thô)
    ------------------------------------------------------------
    INSERT INTO LichSuTruyCap(TaiKhoan, ThoiGian, HanhDong, IPAddress, UserAgent, Ext)
    SELECT v.TaiKhoan, v.ThoiGian, v.HanhDong, v.IP, v.UA, 'seed'
    FROM (VALUES
        ('tung',      DATEADD(MINUTE,-40,GETDATE()), N'Đăng nhập',             '127.0.0.1', N'SSRS/Browser'),
        ('hoangminh', DATEADD(MINUTE,-30,GETDATE()), N'Xem bản đồ công trình', '127.0.0.1', N'Browser'),
        ('admin',     DATEADD(MINUTE,-20,GETDATE()), N'Xem log hệ thống',      '127.0.0.1', N'SSMS')
    ) v(TaiKhoan, ThoiGian, HanhDong, IP, UA)
    WHERE NOT EXISTS (
        SELECT 1 FROM LichSuTruyCap l
        WHERE l.TaiKhoan=v.TaiKhoan AND l.HanhDong=v.HanhDong AND l.IPAddress=v.IP
    );

    INSERT INTO LichSuTacDong(NguoiThucHien, ThoiGian, BangTacDong, IdBanGhi, LoaiTacDong, NoiDungThayDoi, Ext)
    SELECT v.Nguoi, GETDATE(), v.Bang, v.IdBanGhi, v.Loai, v.NoiDung, 'seed'
    FROM (VALUES
        ('tung',      N'VanBanPhapLuatNuocSachVSMT', 1, N'THEM', N'Thêm văn bản 01/2024/QĐ-UBND'),
        ('hoangminh', N'CongTrinhTapTrung',          1, N'THEM', N'Thêm công trình tập trung'),
        ('admin',     N'Quyen',                       1, N'SUA', N'Cập nhật mô tả quyền')
    ) v(Nguoi, Bang, IdBanGhi, Loai, NoiDung)
    WHERE NOT EXISTS (
        SELECT 1 FROM LichSuTacDong l
        WHERE l.NguoiThucHien=v.Nguoi AND l.BangTacDong=v.Bang AND l.IdBanGhi=v.IdBanGhi AND l.LoaiTacDong=v.Loai
    );

    ------------------------------------------------------------
    -- L) PHIÊN ĐĂNG NHẬP + QUÊN MẬT KHẨU
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM PhienDangNhap WHERE Token='token-demo-1')
        INSERT INTO PhienDangNhap(TaiKhoan, ThoiGianDangNhap, ThoiGianDangXuat, IPAddress, Token, Ext)
        VALUES('tung', DATEADD(HOUR,-2,GETDATE()), DATEADD(HOUR,-1,GETDATE()), '127.0.0.1', 'token-demo-1', 'seed');

    IF NOT EXISTS (SELECT 1 FROM PhienDangNhap WHERE Token='token-demo-2')
        INSERT INTO PhienDangNhap(TaiKhoan, ThoiGianDangNhap, ThoiGianDangXuat, IPAddress, Token, Ext)
        VALUES('hoangminh', DATEADD(HOUR,-1,GETDATE()), NULL, '127.0.0.1', 'token-demo-2', 'seed');

    IF NOT EXISTS (SELECT 1 FROM DatLaiMatKhau WHERE MaXacNhan='OTP-123456')
        INSERT INTO DatLaiMatKhau(TaiKhoan, MaXacNhan, HetHan, DaDung, NgayTao, Ext)
        VALUES ('hoangminh', 'OTP-123456', DATEADD(MINUTE,15,GETDATE()), 0, GETDATE(), 'seed');

    COMMIT TRAN;

    PRINT N'✔ Seed OK (không trùng admin).';
    PRINT N'✔ Accounts: admin/admin123 | tung/1234 | hoangminh/1234';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    PRINT N'✘ Seed FAIL: ' + ERROR_MESSAGE();
END CATCH;

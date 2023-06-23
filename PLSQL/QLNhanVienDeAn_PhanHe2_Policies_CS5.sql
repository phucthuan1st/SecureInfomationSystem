CONNECT COMPANY_PUBLIC/astrongpassword@localhost:1521/COMPANY;

SET SERVEROUTPUT ON

DECLARE
  v_service_name VARCHAR2(100);
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SERVICE_NAME') INTO v_service_name FROM DUAL;
  DBMS_OUTPUT.PUT_LINE('Service Name: ' || v_service_name);
END;
/

/* =========== CÀI ĐẶT CÁC CHÍNH SÁCH DÙNG VPD ============= */

-------------------------------------------------------------------------------------------------------------------------------------
/*
CS#5: Những người dùng có VAITRO là “Nhân sự” cho biết đó là nhân viên phụ trách công tác
nhân sự trong công ty. Một người dùng có VAITRO là “Nhân sự” có quyền được mô tả như sau:
− Có quyền như là một nhân viên thông thường (vai trò “Nhân viên”).
− Được quyền thêm, cập nhật trên quan hệ PHONGBAN.
− Thêm, cập nhật dữ liệu trong quan hệ NHANVIEN với giá trị các trường LUONG, PHUCAP
là mang giá trị mặc định là NULL, không được xem LUONG, PHUCAP của người khác và
không được cập nhật trên các trường LUONG, PHUCAP.
*/
-- 1. Quyền SELECT
CREATE OR REPLACE FUNCTION NHANSU_PERMISSION_CONSTRAINTS (
  schema_name   IN VARCHAR2,
  object_name   IN VARCHAR2
)
RETURN VARCHAR2
IS
  vaitro NVARCHAR2(20);
BEGIN
        -- Lấy vai trò của user hiện tại
    SELECT VAITRO INTO vaitro FROM COMPANY_PUBLIC.NHANVIEN WHERE MANV = SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    -- Truy cập dòng liên quan đến nhân viên đó
    IF object_name = 'NHANVIEN' THEN
        IF vaitro = 'Nhân sự' THEN
             RETURN 'MANV = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
        END IF;
    
    -- Truy cập dòng liên quan đến nhân viên đó
    ELSIF object_name = 'PHANCONG' THEN
        IF vaitro = 'Nhân sự' THEN
             RETURN 'MANV = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';
        END IF;
    
    -- tùy ý truy cập phòng ban và đề án
    ELSIF object_name = 'PHONGBAN' or object_name = 'DEAN' THEN
        IF vaitro = 'Nhân sự' THEN
            RETURN '1=1';
        END IF;
    END IF;
  
  RETURN NULL;
END;
/

-- *NOTE: đối với hàm chính sách, return NULL để có vô hiệu hóa điều kiện, để có thể gắn thêm các chính sách khác (các CS2 --> 6)

BEGIN
    -- Có quyền xem trên quan hệ NHANVIEN của chính nhân viên đó
    DBMS_RLS.ADD_POLICY(
        object_schema    => 'COMPANY_PUBLIC',
        object_name      => 'NHANVIEN',
        policy_name      => 'NHANSU_SELECT_NHANVIEN_POLICY',
        function_schema  => 'COMPANY_PUBLIC',
        policy_function  => 'NHANSU_PERMISSION_CONSTRAINTS',
        statement_types  => 'SELECT'
    );
    --Có quyền thêm, chỉnh sửa tất cả các thuộc tính trừ LUONG, PHUCAP trên quan hệ NHANVIEN 
    DBMS_RLS.ADD_POLICY(
        object_schema    => 'COMPANY_PUBLIC',
        object_name      => 'NHANVIEN',
        policy_name      => 'NHANSU_INSERT_UPDATE_NHANVIEN_POLICY',
        function_schema  => 'COMPANY_PUBLIC',
        policy_function  => 'NHANSU_PERMISSION_CONSTRAINTS',
        statement_types  => 'INSERT,UPDATE'
        sec_relevant_cols => 'MANV,TENNV,PHAI,NGAYSINH,DIACHI,SDT,VAITRO,MANQL,PHG'
    );
    
    -- Có quyền xem tất cả các thuộc tính trên quan hệ PHANCONG của chính nhân viên đó
    DBMS_RLS.ADD_POLICY(
        object_schema    => 'COMPANY_PUBLIC',
        object_name      => 'PHANCONG',
        policy_name      => 'NHANSU_SELECT_PHANCONG_POLICY',
        function_schema  => 'COMPANY_PUBLIC',
        policy_function  => 'NHANSU_PERMISSION_CONSTRAINTS',
        statement_types  => 'SELECT'
    );
    
    -- Có thể xem, thêm, cập nhật dữ liệu của toàn bộ quan hệ PHONGBAN
    DBMS_RLS.ADD_POLICY(
        object_schema    => 'COMPANY_PUBLIC',
        object_name      => 'PHONGBAN',
        policy_name      => 'NHANSU_SELECT_PHONGBAN_POLICY',
        function_schema  => 'COMPANY_PUBLIC',
        policy_function  => 'NHANSU_PERMISSION_CONSTRAINTS',
        statement_types  => 'SELECT,INSERT,UPDATE'
    );
    
    --Có thể xem dữ liệu của toàn bộ quan hệ DEAN
    DBMS_RLS.ADD_POLICY(
        object_schema    => 'COMPANY_PUBLIC',
        object_name      => 'DEAN',
        policy_name      => 'NHANSU_SELECT_DEAN_POLICY',
        function_schema  => 'COMPANY_PUBLIC',
        policy_function  => 'NHANSU_PERMISSION_CONSTRAINTS',
        statement_types  => 'SELECT'
    );
    ----------------------------------------------------------------------------------------
    -- Có thể sửa trên các thuộc tính NGAYSINH, DIACHI, SODT liên quan đến chính nhân viên đó.
    DBMS_RLS.ADD_POLICY(
        object_schema    => 'COMPANY_PUBLIC',
        object_name      => 'NHANVIEN',
        policy_name      => 'NHANVIEN_UPDATE_NHANVIEN_POLICY',
        function_schema  => 'COMPANY_PUBLIC',
        policy_function  => 'NHANVIEN_PERMISSION_CONSTRAINTS',
        statement_types  => 'UPDATE',
        sec_relevant_cols => 'NGAYSINH, DIACHI, SODT'
    );
END;
/
-------------------------------------------------------------------------------------------------------------------------------------

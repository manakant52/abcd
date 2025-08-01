-- Drop tables if exist (for clean installation)
DROP TABLE IF EXISTS maintenance_records;
DROP TABLE IF EXISTS water_analysis;
DROP TABLE IF EXISTS well_production;
DROP TABLE IF EXISTS wells;
DROP TABLE IF EXISTS owners;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS technical_notes;

-- Regions table
CREATE TABLE regions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    geological_zone VARCHAR(100),
    average_depth INT
);

-- Drilling companies table
CREATE TABLE companies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200) NOT NULL,
    registration_number VARCHAR(50) UNIQUE,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    license_number VARCHAR(50),
    license_expiry DATE,
    rating DECIMAL(2,1),
    established_year INT
);

-- Well owners table
CREATE TABLE owners (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(200) NOT NULL,
    passport_series VARCHAR(10),
    passport_number VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    registration_date DATE,
    is_commercial BOOLEAN DEFAULT FALSE
);

-- Main wells table
CREATE TABLE wells (
    id INT PRIMARY KEY AUTO_INCREMENT,
    well_number VARCHAR(50) UNIQUE NOT NULL,
    owner_id INT,
    company_id INT,
    region_id INT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    depth_meters INT,
    diameter_mm INT,
    drilling_date DATE,
    commissioning_date DATE,
    water_level_static INT,
    water_level_dynamic INT,
    flow_rate_m3_hour DECIMAL(10,2),
    pump_type VARCHAR(100),
    pump_power_kw DECIMAL(5,2),
    status ENUM('active', 'inactive', 'maintenance', 'abandoned') DEFAULT 'active',
    license_number VARCHAR(50),
    cadastral_number VARCHAR(50),
    FOREIGN KEY (owner_id) REFERENCES owners(id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (region_id) REFERENCES regions(id)
);

-- Water analysis table
CREATE TABLE water_analysis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    well_id INT,
    analysis_date DATE,
    ph_level DECIMAL(3,1),
    hardness_mg_l DECIMAL(10,2),
    iron_mg_l DECIMAL(10,4),
    chlorides_mg_l DECIMAL(10,2),
    sulfates_mg_l DECIMAL(10,2),
    nitrates_mg_l DECIMAL(10,2),
    mineralization_g_l DECIMAL(10,3),
    temperature_c DECIMAL(4,1),
    bacteriological_safe BOOLEAN,
    laboratory_name VARCHAR(200),
    certificate_number VARCHAR(50),
    FOREIGN KEY (well_id) REFERENCES wells(id)
);

-- Well production table
CREATE TABLE well_production (
    id INT PRIMARY KEY AUTO_INCREMENT,
    well_id INT,
    measurement_date DATE,
    daily_production_m3 DECIMAL(10,2),
    water_consumed_m3 DECIMAL(10,2),
    electricity_kwh DECIMAL(10,2),
    pressure_bar DECIMAL(5,2),
    notes TEXT,
    FOREIGN KEY (well_id) REFERENCES wells(id)
);

-- Maintenance records table
CREATE TABLE maintenance_records (
    id INT PRIMARY KEY AUTO_INCREMENT,
    well_id INT,
    maintenance_date DATE,
    maintenance_type ENUM('routine', 'repair', 'cleaning', 'pump_replacement', 'emergency'),
    description TEXT,
    cost_rub DECIMAL(12,2),
    contractor_company_id INT,
    next_maintenance_date DATE,
    FOREIGN KEY (well_id) REFERENCES wells(id),
    FOREIGN KEY (contractor_company_id) REFERENCES companies(id)
);

-- Technical notes table (actually secret)
CREATE TABLE technical_notes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    note_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    category VARCHAR(50),
    priority VARCHAR(20),
    note_text TEXT,
    author VARCHAR(100),
    is_archived BOOLEAN DEFAULT FALSE
);

-- Insert data

-- Regions
INSERT INTO regions (name, geological_zone, average_depth) VALUES
('Moscow Region', 'Moscow Artesian Basin', 150),
('Leningrad Region', 'Baltic Artesian Basin', 120),
('Krasnodar Territory', 'Azov-Kuban Basin', 200),
('Novosibirsk Region', 'West Siberian Basin', 180);

-- Companies
INSERT INTO companies (name, registration_number, address, phone, email, license_number, license_expiry, rating, established_year) VALUES
('AquaDrill Pro', '1234567890123', '15 Industrial St, Moscow', '+7-495-123-45-67', 'info@aquadrill.com', 'MSK-123-2022', '2027-12-31', 4.8, 2010),
('HydroGeology Plus', '2345678901234', '28 Science Ave, St Petersburg', '+7-812-987-65-43', 'contact@hydroplus.com', 'SPB-456-2021', '2026-06-30', 4.5, 2008),
('Artesian Systems', '3456789012345', '102 North St, Krasnodar', '+7-861-555-12-34', 'office@artsys.com', 'KRD-789-2023', '2028-03-15', 4.9, 2015),
('SibWaterBuild', '4567890123456', '45 Soviet St, Novosibirsk', '+7-383-222-33-44', 'sibwater@mail.com', 'NSK-321-2022', '2027-09-01', 4.2, 2005);

-- Owners (including Maxim Smirnov)
INSERT INTO owners (full_name, passport_series, passport_number, phone, email, address, registration_date, is_commercial) VALUES
('Maxim Smirnov', '4510', '123456', '+7-916-123-45-67', 'maxim.smirnov@email.com', '25 Garden St, Odintsovo, Moscow Region', '2023-05-15', FALSE),
('Peter Ivanov', '4511', '234567', '+7-495-111-22-33', 'ivanov@mail.com', '10 Lenin St, Moscow', '2022-03-20', FALSE),
('AgroComplex LLC', NULL, NULL, '+7-495-999-88-77', 'info@agrocomplex.com', 'Dmitrov District, Moscow Region', '2021-07-10', TRUE),
('Elena Sidorova', '4512', '345678', '+7-916-444-55-66', 'sidorova@gmail.com', '15 Peace St, Khimki, Moscow Region', '2023-01-25', FALSE),
('Clean Water JSC', NULL, NULL, '+7-812-777-66-55', 'office@cleanwater.com', '100 Vyborg Highway, St Petersburg', '2022-11-30', TRUE);

-- Wells (including Maxim Smirnov's well)
INSERT INTO wells (well_number, owner_id, company_id, region_id, latitude, longitude, depth_meters, diameter_mm, drilling_date, commissioning_date, water_level_static, water_level_dynamic, flow_rate_m3_hour, pump_type, pump_power_kw, status, license_number, cadastral_number) VALUES
('MSK-2023-0156', 1, 1, 1, 55.6768, 37.2797, 140, 133, '2023-05-20', '2023-05-25', 45, 52, 3.5, 'Grundfos SQ 3-105', 2.2, 'active', 'WP-MR-2023-0156', '50:20:0010203:1234'),
('MSK-2022-0089', 2, 1, 1, 55.7558, 37.6173, 155, 152, '2022-03-25', '2022-04-01', 50, 58, 4.2, 'Pedrollo 4SR', 3.0, 'active', 'WP-MR-2022-0089', '50:10:0020304:5678'),
('MSK-2021-0234', 3, 1, 1, 55.8304, 37.3300, 180, 168, '2021-07-15', '2021-07-20', 55, 65, 8.5, 'Wilo TWI 4-0220', 5.5, 'active', 'WP-MR-2021-0234', '50:11:0030405:9012'),
('MSK-2023-0045', 4, 1, 1, 55.8963, 37.4103, 135, 133, '2023-02-01', '2023-02-05', 42, 48, 3.2, 'Grundfos SQ 2-85', 1.85, 'maintenance', 'WP-MR-2023-0045', '50:45:0040506:3456'),
('SPB-2022-0178', 5, 2, 2, 59.9311, 30.3609, 120, 152, '2022-12-05', '2022-12-10', 35, 42, 5.5, 'DAB Divertron 1200', 4.0, 'active', 'WP-LR-2022-0178', '47:25:0050607:7890');

-- Water analysis
INSERT INTO water_analysis (well_id, analysis_date, ph_level, hardness_mg_l, iron_mg_l, chlorides_mg_l, sulfates_mg_l, nitrates_mg_l, mineralization_g_l, temperature_c, bacteriological_safe, laboratory_name, certificate_number) VALUES
(1, '2023-06-15', 7.2, 4.5, 0.15, 25.3, 45.2, 8.5, 0.35, 8.5, TRUE, 'EcoLab Analysis', 'EL-2023-4567'),
(1, '2023-12-20', 7.3, 4.8, 0.18, 26.1, 44.8, 9.2, 0.36, 8.2, TRUE, 'EcoLab Analysis', 'EL-2023-9876'),
(2, '2022-05-10', 7.5, 5.2, 0.22, 30.5, 52.3, 12.1, 0.42, 9.0, TRUE, 'AquaTest', 'AT-2022-3421'),
(3, '2021-08-20', 6.9, 6.8, 0.35, 45.2, 78.9, 15.6, 0.58, 8.8, TRUE, 'Water Control', 'WC-2021-8765'),
(4, '2023-03-10', 7.1, 4.2, 0.12, 22.8, 41.5, 7.2, 0.32, 8.6, TRUE, 'EcoLab Analysis', 'EL-2023-1234');

-- Production data
INSERT INTO well_production (well_id, measurement_date, daily_production_m3, water_consumed_m3, electricity_kwh, pressure_bar, notes) VALUES
(1, '2024-01-15', 45.6, 42.3, 28.5, 3.2, 'Stable operation'),
(1, '2024-02-15', 44.8, 41.5, 27.8, 3.1, 'Slight flow decrease'),
(2, '2024-01-15', 58.3, 55.2, 42.6, 3.8, 'Optimal performance'),
(3, '2024-01-15', 125.4, 118.9, 85.3, 4.2, 'High productivity'),
(4, '2024-01-15', 38.2, 35.6, 22.4, 2.9, 'Cleaning required');

-- Maintenance records
INSERT INTO maintenance_records (well_id, maintenance_date, maintenance_type, description, cost_rub, contractor_company_id, next_maintenance_date) VALUES
(1, '2023-10-15', 'routine', 'Routine equipment inspection, filter replacement', 15000.00, 1, '2024-04-15'),
(2, '2023-09-20', 'cleaning', 'Well flushing, sand removal', 35000.00, 1, '2024-09-20'),
(3, '2023-08-10', 'pump_replacement', 'Submersible pump replacement', 85000.00, 1, '2025-08-10'),
(4, '2024-01-25', 'repair', 'Automation system repair', 22000.00, 1, '2024-07-25'),
(5, '2023-11-30', 'routine', 'Preventive maintenance', 18000.00, 2, '2024-05-30');

-- Insert data into technical_notes (including secret flag)
INSERT INTO technical_notes (category, priority, note_text, author, is_archived) VALUES
('calibration', 'low', 'Check pressure sensor calibration on well MSK-2022-0089', 'A.Petrov', FALSE),
('maintenance', 'medium', 'Schedule seal ring replacement for all wells in region 1', 'I.Sidorov', FALSE),
('system', 'high', 'letoctf{w3l1c0m3_70_MoRz3_cu1t}', 'admin', TRUE),
('equipment', 'low', 'Order spare filters for Grundfos pumps', 'S.Ivanov', FALSE),
('water_quality', 'medium', 'Elevated iron content in Dmitrov district wells', 'E.Kozlova', FALSE),
('backup', 'low', 'Backup completed successfully 2024-01-20', 'system', TRUE),
('security', 'medium', 'Update telemetry system access passwords', 'Administrator', FALSE);

-- Seed data — lists taken from the SyyncIn Figma screens (V3). Safe to re-run.
SET NAMES utf8mb4;

INSERT IGNORE INTO industries (name, sort_order) VALUES
('Information Technology',1),('Design & Creative',2),('Finance & Banking',3),('Marketing & Advertising',4),
('Healthcare',5),('Education',6),('Manufacturing',7),('Real Estate',8),('Consulting',9),
('Retail & E-commerce',10),('Media & Entertainment',11),('Other',12);

INSERT IGNORE INTO experience_levels (label, min_years, max_years, sort_order) VALUES
('Less than 1 year',0,0,1),('1–2 years',1,2,2),('3–5 years',3,5,3),('6–10 years',6,10,4),('10+ years',10,NULL,5);

INSERT IGNORE INTO skills (name, sort_order) VALUES
('UI/UX Design',1),('Product Management',2),('Flutter',3),('iOS (Swift)',4),('Android (Kotlin)',5),
('React',6),('Node.js',7),('Data Analysis',8),('Digital Marketing',9),('Content Writing',10),
('Sales',11),('Business Development',12),('Project Management',13),('Finance',14),('Leadership',15),
('Public Speaking',16),('Graphic Design',17),('SEO',18),('Machine Learning',19),('Photography',20);

INSERT IGNORE INTO interests (name, sort_order) VALUES
('Technology',1),('Business',2),('Startups',3),('Design',4),('Marketing',5),('AI',6),('Product',7),
('Finance',8),('Career growth',9),('Freelancing',10),('Networking',11),('Content',12),('Social media',13),
('Travel',14),('Wellness',15),('Food & coffee',16),('Books',17),('Sports',18),('Music',19),('Art',20),('Community',21);

INSERT IGNORE INTO reasons (title, subtitle, icon, sort_order) VALUES
('Grow my network','Meet professionals beyond my circle','users',1),
('Exchange ideas','Have meaningful conversations','bulb',2),
('Find collaborators','Build and work on something together','handshake',3),
('Learn from others','Share knowledge and experiences','graduation',4),
('Explore opportunities','Discover career and business possibilities','trend_up',5),
('Meet in person','Connect with professionals nearby','coffee',6);

INSERT INTO mindset_questions (id, question, sort_order) VALUES
(1,'What motivates you most?',1),(2,'How do you approach new ideas?',2),(3,'How do you like to connect?',3),
(4,'What matters most to you?',4),(5,'Who would you like to meet?',5)
ON DUPLICATE KEY UPDATE question = VALUES(question);

INSERT IGNORE INTO mindset_options (question_id, label, sort_order) VALUES
(1,'Growth',1),(1,'Building',2),(1,'Impact',3),(1,'Success',4),
(2,'Creative',1),(2,'Practical',2),(2,'Analytical',3),(2,'Balanced',4),
(3,'1-to-1',1),(3,'Share ideas',2),(3,'Collaborate',3),(3,'Meet in person',4),
(4,'Trust',1),(4,'Ambition',2),(4,'Creativity',3),(4,'Knowledge',4),
(5,'Shared interests',1),(5,'Different skills',2),(5,'Fresh perspectives',3),(5,'Similar goals',4);

INSERT IGNORE INTO cities (name, state, lat, lng, sort_order) VALUES
('Ahmedabad','Gujarat',23.022505,72.571365,1),('Gandhinagar','Gujarat',23.215635,72.636941,2),
('Vadodara','Gujarat',22.307159,73.181219,3),('Surat','Gujarat',21.170240,72.831061,4),
('Mumbai','Maharashtra',19.076090,72.877426,5),('Pune','Maharashtra',18.520430,73.856744,6),
('Bengaluru','Karnataka',12.971599,77.594566,7),('Hyderabad','Telangana',17.385044,78.486671,8),
('Delhi','Delhi',28.704060,77.102493,9),('Chennai','Tamil Nadu',13.082680,80.270718,10);

INSERT IGNORE INTO localities (city_id, name, sort_order)
SELECT c.id, l.name, l.ord FROM cities c
JOIN (SELECT 'South Bopal' name, 1 ord UNION ALL SELECT 'Bopal',2 UNION ALL SELECT 'Satellite',3
      UNION ALL SELECT 'Prahlad Nagar',4 UNION ALL SELECT 'SG Highway',5 UNION ALL SELECT 'Vastrapur',6
      UNION ALL SELECT 'Navrangpura',7 UNION ALL SELECT 'Thaltej',8 UNION ALL SELECT 'Maninagar',9
      UNION ALL SELECT 'Chandkheda',10) l
WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';

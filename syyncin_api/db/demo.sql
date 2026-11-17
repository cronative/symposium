-- Demo members for KYN / Profile / Inbox (dev only). Safe to re-run.
-- Load with: npm run db:demo   (or npm run db:reset -- --demo)
SET NAMES utf8mb4;

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000001', 'Krupa Shah', '1988-01-15', 'woman', 'UI/UX Designer', (SELECT id FROM industries WHERE name = 'Design & Creative'), 'Airbnb', (SELECT id FROM experience_levels WHERE label = '3–5 years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'South Bopal'), 23.0219, 72.4714, 'both', 25, '["weekends"]', 1, 1, 'I enjoy designing intuitive digital experiences and collaborating on meaningful ideas.', 7, 'verified', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('UI/UX Design', 'Graphic Design') WHERE u.phone = '+919000000001';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Design', 'Technology', 'Startups') WHERE u.phone = '+919000000001';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Grow my network', 'Exchange ideas') WHERE u.phone = '+919000000001';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Growth'),(2,'Creative'),(3,'Collaborate'),(4,'Trust'),(5,'Shared interests')) WHERE u.phone = '+919000000001';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000002', 'Parth Mehta', '1989-02-15', 'man', 'Product Manager', (SELECT id FROM industries WHERE name = 'Information Technology'), 'Razorpay', (SELECT id FROM experience_levels WHERE label = '6–10 years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'Bopal'), 23.0336, 72.4637, 'in_person', 25, '["evenings"]', 1, 1, 'Building fintech products. Always up for a coffee chat about product.', 7, 'verified', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Product Management', 'Data Analysis') WHERE u.phone = '+919000000002';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Product', 'Business', 'Networking') WHERE u.phone = '+919000000002';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Find collaborators') WHERE u.phone = '+919000000002';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Building'),(2,'Practical'),(3,'1-to-1'),(4,'Ambition'),(5,'Different skills')) WHERE u.phone = '+919000000002';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000003', 'Riddhi Trivedi', '1990-03-15', 'woman', 'Marketing Specialist', (SELECT id FROM industries WHERE name = 'Marketing & Advertising'), 'Zomato', (SELECT id FROM experience_levels WHERE label = '3–5 years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'Satellite'), 23.0301, 72.5176, 'online', 25, '["weekdays"]', 1, 1, NULL, 7, 'pending', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Digital Marketing', 'Content Writing') WHERE u.phone = '+919000000003';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Marketing', 'Content', 'Startups') WHERE u.phone = '+919000000003';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Exchange ideas') WHERE u.phone = '+919000000003';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Impact'),(2,'Analytical'),(3,'Share ideas'),(4,'Creativity'),(5,'Fresh perspectives')) WHERE u.phone = '+919000000003';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000004', 'Amit Joshi', '1991-04-15', 'man', 'Software Engineer', (SELECT id FROM industries WHERE name = 'Information Technology'), 'TCS', (SELECT id FROM experience_levels WHERE label = '6–10 years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'Prahlad Nagar'), 23.012, 72.5108, 'both', 25, '["flexible"]', 1, 1, 'Mobile + backend engineer. Happy to help with Flutter questions.', 7, 'verified', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Flutter', 'Node.js') WHERE u.phone = '+919000000004';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Technology', 'AI', 'Startups') WHERE u.phone = '+919000000004';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Learn from others') WHERE u.phone = '+919000000004';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Growth'),(2,'Creative'),(3,'Collaborate'),(4,'Trust'),(5,'Shared interests')) WHERE u.phone = '+919000000004';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000005', 'Neha Patel', '1992-05-15', 'woman', 'Business Analyst', (SELECT id FROM industries WHERE name = 'Finance & Banking'), 'CRED', (SELECT id FROM experience_levels WHERE label = '3–5 years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'Vastrapur'), 23.0379, 72.529, 'online', 25, '["evenings"]', 1, 1, NULL, 7, 'pending', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Data Analysis', 'Finance') WHERE u.phone = '+919000000005';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Business', 'Finance', 'Product') WHERE u.phone = '+919000000005';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Explore opportunities') WHERE u.phone = '+919000000005';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Building'),(2,'Practical'),(3,'1-to-1'),(4,'Ambition'),(5,'Different skills')) WHERE u.phone = '+919000000005';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000006', 'Darshan Shah', '1993-06-15', 'man', 'Founder', (SELECT id FROM industries WHERE name = 'Consulting'), 'Freelance', (SELECT id FROM experience_levels WHERE label = '10+ years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'SG Highway'), 23.0469, 72.53, 'in_person', 25, '["weekends"]', 1, 1, 'Two-time founder, now advising early-stage teams in Ahmedabad.', 7, 'verified', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Leadership', 'Business Development') WHERE u.phone = '+919000000006';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Startups', 'Business', 'Networking') WHERE u.phone = '+919000000006';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Find collaborators', 'Meet in person') WHERE u.phone = '+919000000006';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Impact'),(2,'Analytical'),(3,'Share ideas'),(4,'Creativity'),(5,'Fresh perspectives')) WHERE u.phone = '+919000000006';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000007', 'Priya Mehta', '1994-07-15', 'woman', 'Content Strategist', (SELECT id FROM industries WHERE name = 'Media & Entertainment'), 'Swiggy', (SELECT id FROM experience_levels WHERE label = '1–2 years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'Navrangpura'), 23.0365, 72.5611, 'both', 25, '["weekends"]', 1, 1, NULL, 7, 'pending', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Content Writing', 'SEO') WHERE u.phone = '+919000000007';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Content', 'Social media', 'Design') WHERE u.phone = '+919000000007';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Grow my network') WHERE u.phone = '+919000000007';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Growth'),(2,'Creative'),(3,'Collaborate'),(4,'Trust'),(5,'Shared interests')) WHERE u.phone = '+919000000007';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000008', 'Karan Desai', '1995-08-15', 'man', 'Data Analyst', (SELECT id FROM industries WHERE name = 'Information Technology'), 'Zoho', (SELECT id FROM experience_levels WHERE label = 'Less than 1 year'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'Chandkheda'), 23.109, 72.585, 'online', 25, '["flexible"]', 1, 1, NULL, 7, 'pending', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Data Analysis', 'Machine Learning') WHERE u.phone = '+919000000008';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('AI', 'Technology', 'Finance') WHERE u.phone = '+919000000008';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Learn from others') WHERE u.phone = '+919000000008';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Building'),(2,'Practical'),(3,'1-to-1'),(4,'Ambition'),(5,'Different skills')) WHERE u.phone = '+919000000008';

INSERT IGNORE INTO users (phone, full_name, dob, gender, job_title, industry_id, company, experience_level_id, city_id, locality_id, lat, lng, connect_mode, radius_km, availability, nearby_discovery, open_to_connect, about, onboarding_step, verification_status, terms_accepted_at)
SELECT '+919000000009', 'Aarav Mehta', '1996-09-15', 'man', 'Product Manager', (SELECT id FROM industries WHERE name = 'Information Technology'), 'Paytm', (SELECT id FROM experience_levels WHERE label = '6–10 years'),
       c.id, (SELECT id FROM localities WHERE city_id = c.id AND name = 'Thaltej'), 23.05, 72.499, 'both', 25, '["evenings"]', 1, 1, 'PM who loves meeting builders in the neighbourhood.', 7, 'verified', NOW()
  FROM cities c WHERE c.name = 'Ahmedabad' AND c.state = 'Gujarat';
INSERT IGNORE INTO user_skills (user_id, skill_id) SELECT u.id, m.id FROM users u JOIN skills m ON m.name IN ('Product Management', 'Project Management') WHERE u.phone = '+919000000009';
INSERT IGNORE INTO user_interests (user_id, interest_id) SELECT u.id, m.id FROM users u JOIN interests m ON m.name IN ('Product', 'Networking', 'Startups') WHERE u.phone = '+919000000009';
INSERT IGNORE INTO user_reasons (user_id, reason_id) SELECT u.id, m.id FROM users u JOIN reasons m ON m.title IN ('Exchange ideas', 'Grow my network') WHERE u.phone = '+919000000009';
INSERT IGNORE INTO user_mindset_answers (user_id, question_id, option_id) SELECT u.id, o.question_id, o.id FROM users u JOIN mindset_options o ON (o.question_id, o.label) IN ((1,'Impact'),(2,'Analytical'),(3,'Share ideas'),(4,'Creativity'),(5,'Fresh perspectives')) WHERE u.phone = '+919000000009';

-- Existing demo connections: Krupa ↔ Riddhi, Krupa ↔ Neha (so Krupa's Inbox isn't empty when you log in as her).
INSERT IGNORE INTO connections (user_a_id, user_b_id) SELECT LEAST(x.id, y.id), GREATEST(x.id, y.id) FROM users x, users y WHERE x.phone = '+919000000001' AND y.phone = '+919000000003';
INSERT IGNORE INTO connections (user_a_id, user_b_id) SELECT LEAST(x.id, y.id), GREATEST(x.id, y.id) FROM users x, users y WHERE x.phone = '+919000000001' AND y.phone = '+919000000005';
-- Aarav → Krupa pending request (Inbox › Requests › Received).
INSERT IGNORE INTO connection_requests (sender_id, receiver_id, message) SELECT s.id, r.id, 'Hi Krupa, I''d love to connect and exchange ideas.' FROM users s, users r WHERE s.phone = '+919000000009' AND r.phone = '+919000000001'
   AND NOT EXISTS (SELECT 1 FROM connections c WHERE c.user_a_id = LEAST(s.id, r.id) AND c.user_b_id = GREATEST(s.id, r.id))
   AND NOT EXISTS (SELECT 1 FROM connection_requests x WHERE x.sender_id = s.id AND x.receiver_id = r.id);

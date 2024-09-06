-- Create the tables
CREATE TABLE headlines (
    id SERIAL PRIMARY KEY,
    subject VARCHAR(255),
    content TEXT,
    published_at TIMESTAMP
);

CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    category VARCHAR(64)
);

CREATE TABLE tag_labels (
    id SERIAL PRIMARY KEY,
    tag_id INT REFERENCES tags(id),
    name VARCHAR(64)
);

CREATE TABLE headline_tags (
    id SERIAL PRIMARY KEY,
    headline_id INT REFERENCES headlines(id),
    tag_id INT REFERENCES tags(id),
    weight FLOAT
);

CREATE TABLE tag_relations (
    id SERIAL PRIMARY KEY,
    source_tag_id INT REFERENCES tags(id),
    target_tag_id INT REFERENCES tags(id),
    strength FLOAT
);

-- Insert tags
INSERT INTO tags (category) VALUES
('UK'),
('Bank of England'),
('Central Banks'),
('Europe'),
('Fixed Income'),
('Oil'),
('Commodities');

-- Insert tag labels (aliases)
INSERT INTO tag_labels (tag_id, name) VALUES
((SELECT id FROM tags WHERE category='UK'), 'United Kingdom'),
((SELECT id FROM tags WHERE category='Bank of England'), 'BoE'),
((SELECT id FROM tags WHERE category='Oil'), 'Crude'),
((SELECT id FROM tags WHERE category='Oil'), 'WTI');

-- Insert tag relations
INSERT INTO tag_relations (source_tag_id, target_tag_id, strength) VALUES
((SELECT id FROM tags WHERE category='UK'), (SELECT id FROM tags WHERE category='Europe'), 0.9),
((SELECT id FROM tags WHERE category='Bank of England'), (SELECT id FROM tags WHERE category='UK'), 0.8),
((SELECT id FROM tags WHERE category='Bank of England'), (SELECT id FROM tags WHERE category='Central Banks'), 0.85),
((SELECT id FROM tags WHERE category='Central Banks'), (SELECT id FROM tags WHERE category='Fixed Income'), 0.75),
((SELECT id FROM tags WHERE category='Oil'), (SELECT id FROM tags WHERE category='Commodities'), 0.9);

-- Insert headlines
INSERT INTO headlines (subject, content, published_at) VALUES
('Bank of England Raises Interest Rates', 'The Bank of England has increased interest rates in response to rising inflation.', NOW()),
('Oil Prices Surge Amid Global Tensions', 'Crude oil prices have hit a new high due to geopolitical uncertainties.', NOW()),
('European Markets Steady', 'Stock markets across Europe remain steady despite global economic concerns.', NOW()),
('UK Economy Shows Signs of Recovery', 'Economic indicators suggest that the United Kingdom is recovering post-pandemic.', NOW()),
('Advancements in Renewable Energy', 'Europe leads the way in renewable energy initiatives.', NOW());

-- Link headlines to tags
INSERT INTO headline_tags (headline_id, tag_id, weight) VALUES
-- Headline 1
((SELECT id FROM headlines WHERE subject='Bank of England Raises Interest Rates'), (SELECT id FROM tags WHERE category='Bank of England'), 0.9),
((SELECT id FROM headlines WHERE subject='Bank of England Raises Interest Rates'), (SELECT id FROM tags WHERE category='UK'), 0.8),
((SELECT id FROM headlines WHERE subject='Bank of England Raises Interest Rates'), (SELECT id FROM tags WHERE category='Central Banks'), 0.85),
((SELECT id FROM headlines WHERE subject='Bank of England Raises Interest Rates'), (SELECT id FROM tags WHERE category='Fixed Income'), 0.75),
-- Headline 2
((SELECT id FROM headlines WHERE subject='Oil Prices Surge Amid Global Tensions'), (SELECT id FROM tags WHERE category='Oil'), 0.9),
((SELECT id FROM headlines WHERE subject='Oil Prices Surge Amid Global Tensions'), (SELECT id FROM tags WHERE category='Commodities'), 0.8),
-- Headline 3
((SELECT id FROM headlines WHERE subject='European Markets Steady'), (SELECT id FROM tags WHERE category='Europe'), 0.9),
((SELECT id FROM headlines WHERE subject='European Markets Steady'), (SELECT id FROM tags WHERE category='Fixed Income'), 0.7),
-- Headline 4
((SELECT id FROM headlines WHERE subject='UK Economy Shows Signs of Recovery'), (SELECT id FROM tags WHERE category='UK'), 0.85),
((SELECT id FROM headlines WHERE subject='UK Economy Shows Signs of Recovery'), (SELECT id FROM tags WHERE category='Europe'), 0.8),
-- Headline 5
((SELECT id FROM headlines WHERE subject='Advancements in Renewable Energy'), (SELECT id FROM tags WHERE category='Europe'), 0.9),
((SELECT id FROM headlines WHERE subject='Advancements in Renewable Energy'), (SELECT id FROM tags WHERE category='Commodities'), 0.6);

-- Additional tag relations
INSERT INTO tag_relations (source_tag_id, target_tag_id, strength) VALUES
((SELECT id FROM tags WHERE category='Commodities'), (SELECT id FROM tags WHERE category='Fixed Income'), 0.5);

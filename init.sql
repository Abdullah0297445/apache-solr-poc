-- Create tables
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
    tag_id INT REFERENCES tags(id) ON DELETE CASCADE,
    name VARCHAR(64)
);

CREATE TABLE headline_tags (
    id SERIAL PRIMARY KEY,
    headline_id INT REFERENCES headlines(id) ON DELETE CASCADE,
    tag_id INT REFERENCES tags(id) ON DELETE CASCADE,
    weight FLOAT
);

CREATE TABLE tag_relations (
    id SERIAL PRIMARY KEY,
    source_tag_id INT REFERENCES tags(id) ON DELETE CASCADE,
    target_tag_id INT REFERENCES tags(id) ON DELETE CASCADE,
    strength FLOAT
);

-- Insert into headlines
WITH headlines_data(subject, content) AS (
    VALUES
    ('Global Warming Threatens Coastal Cities', 'The rising sea levels are becoming a major threat to coastal cities across the world. Scientists predict that several major cities could be underwater within the next century.'),
    ('Tech Giants Introduce New AI Innovations', 'Leading tech companies unveil cutting-edge AI technologies designed to revolutionize industries from healthcare to finance.'),
    ('Mars Rover Discovers Water', 'In a groundbreaking discovery, the Mars rover has found evidence of water on the red planet, hinting at the possibility of past life.'),
    ('Olympics Postponed Due to Pandemic', 'The international sporting event has been delayed as a result of the ongoing global pandemic, with safety concerns being the primary reason.'),
    ('Cryptocurrency Reaches New Highs', 'Bitcoin and other cryptocurrencies have reached record-breaking values, drawing in a wave of new investors.'),
    ('Scientists Develop Cure for Rare Disease', 'A team of international scientists has developed a cure for a rare disease, giving hope to millions of affected individuals.'),
    ('Economy Faces Slow Recovery After Recession', 'The global economy is experiencing a slow and uneven recovery following the recent recession, with some sectors showing stronger signs of growth than others.'),
    ('Space Tourism Takes Off', 'A new era of space tourism begins as private companies launch commercial flights to space, giving ordinary citizens a chance to explore the cosmos.'),
    ('New Species Discovered in the Amazon', 'Biologists have discovered several new species of plants and animals in the remote parts of the Amazon rainforest, highlighting the region''s biodiversity.'),
    ('Breakthrough in Quantum Computing', 'Researchers have achieved a significant breakthrough in quantum computing, bringing us one step closer to uncrackable encryption and vastly improved processing power.')
)
INSERT INTO headlines (subject, content, published_at)
SELECT subject, content, NOW() - (ROW_NUMBER() OVER () * interval '1 day')
FROM headlines_data
RETURNING id;

-- Insert tags
WITH tags_data(category) AS (
    VALUES
    ('AI'), ('Climate Change'), ('Economy'), ('Sports'), ('Space'),
    ('Technology'), ('Medicine'), ('Mars'), ('Cryptocurrency'), ('Quantum Computing'),
    ('Animals'), ('Biodiversity'), ('Pandemic'), ('Tourism'), ('Water')
)
INSERT INTO tags (category)
SELECT category
FROM tags_data
RETURNING id, category;

-- Insert tag_labels
WITH tag_aliases(tag_category, name) AS (
    VALUES
    ('AI', 'Artificial Intelligence'), ('AI', 'AI'), ('AI', 'Machine Learning'),
    ('Climate Change', 'Global Warming'), ('Climate Change', 'Climate Change'), ('Climate Change', 'Environmental Crisis'),
    ('Economy', 'Economy'), ('Economy', 'Economic Growth'), ('Economy', 'Financial Market'),
    ('Sports', 'Sports'), ('Sports', 'Athletics'), ('Sports', 'Olympics'),
    ('Space', 'Space'), ('Space', 'Outer Space'), ('Space', 'Universe'),
    ('Technology', 'Technology'), ('Technology', 'Tech'), ('Technology', 'Innovation'),
    ('Medicine', 'Medicine'), ('Medicine', 'Healthcare'), ('Medicine', 'Cure'),
    ('Mars', 'Mars'), ('Mars', 'Red Planet'), ('Mars', 'Mars Rover'),
    ('Cryptocurrency', 'Cryptocurrency'), ('Cryptocurrency', 'Bitcoin'), ('Cryptocurrency', 'Digital Currency'),
    ('Quantum Computing', 'Quantum Computing'), ('Quantum Computing', 'Quantum Physics'), ('Quantum Computing', 'Quantum Technology'),
    ('Animals', 'Animals'), ('Animals', 'Wildlife'), ('Animals', 'Fauna'),
    ('Biodiversity', 'Biodiversity'), ('Biodiversity', 'Ecosystem'), ('Biodiversity', 'Species Diversity'),
    ('Pandemic', 'Pandemic'), ('Pandemic', 'Global Health Crisis'), ('Pandemic', 'COVID-19'),
    ('Tourism', 'Tourism'), ('Tourism', 'Travel'), ('Tourism', 'Space Tourism'),
    ('Water', 'Water'), ('Water', 'Freshwater'), ('Water', 'Water Supply')
)
INSERT INTO tag_labels (tag_id, name)
SELECT tags.id, ta.name
FROM tag_aliases ta
JOIN tags ON ta.tag_category = tags.category;

-- Insert into headline_tags (assign relevant tags to headlines)
WITH relevant_tags(headline_subject, tag_category, weight) AS (
    VALUES
    ('Global Warming Threatens Coastal Cities', 'Climate Change', 9.0),
    ('Global Warming Threatens Coastal Cities', 'Water', 8.5),
    ('Global Warming Threatens Coastal Cities', 'Biodiversity', 7.5),
    ('Tech Giants Introduce New AI Innovations', 'AI', 9.5),
    ('Tech Giants Introduce New AI Innovations', 'Technology', 8.0),
    ('Tech Giants Introduce New AI Innovations', 'Quantum Computing', 8.0),
    ('Mars Rover Discovers Water', 'Mars', 9.0),
    ('Mars Rover Discovers Water', 'Water', 8.5),
    ('Mars Rover Discovers Water', 'Space', 7.0),
    ('Olympics Postponed Due to Pandemic', 'Sports', 9.0),
    ('Olympics Postponed Due to Pandemic', 'Pandemic', 8.5),
    ('Olympics Postponed Due to Pandemic', 'Economy', 7.0),
    ('Cryptocurrency Reaches New Highs', 'Cryptocurrency', 9.5),
    ('Cryptocurrency Reaches New Highs', 'Economy', 8.5),
    ('Cryptocurrency Reaches New Highs', 'Technology', 7.5),
    ('Scientists Develop Cure for Rare Disease', 'Medicine', 9.5),
    ('Scientists Develop Cure for Rare Disease', 'Pandemic', 8.0),
    ('Scientists Develop Cure for Rare Disease', 'Technology', 7.0),
    ('Economy Faces Slow Recovery After Recession', 'Economy', 9.5),
    ('Economy Faces Slow Recovery After Recession', 'Cryptocurrency', 8.5),
    ('Economy Faces Slow Recovery After Recession', 'Pandemic', 7.5),
    ('Space Tourism Takes Off', 'Tourism', 9.5),
    ('Space Tourism Takes Off', 'Space', 9.0),
    ('Space Tourism Takes Off', 'Mars', 8.5),
    ('New Species Discovered in the Amazon', 'Biodiversity', 9.5),
    ('New Species Discovered in the Amazon', 'Animals', 8.5),
    ('New Species Discovered in the Amazon', 'Water', 7.5),
    ('Breakthrough in Quantum Computing', 'Quantum Computing', 9.5),
    ('Breakthrough in Quantum Computing', 'Technology', 8.0),
    ('Breakthrough in Quantum Computing', 'AI', 7.5)
)
INSERT INTO headline_tags (headline_id, tag_id, weight)
SELECT h.id, t.id, rt.weight
FROM relevant_tags rt
JOIN headlines h ON rt.headline_subject = h.subject
JOIN tags t ON rt.tag_category = t.category;

-- Insert into tag_relations
WITH tag_relations_data(source_category, target_category, strength) AS (
    VALUES
    ('AI', 'Technology', 0.9),
    ('Technology', 'AI', 0.9),
    ('Quantum Computing', 'Technology', 0.8),
    ('Technology', 'Quantum Computing', 0.8),
    ('Climate Change', 'Water', 0.7),
    ('Water', 'Climate Change', 0.7),
    ('Climate Change', 'Biodiversity', 0.6),
    ('Biodiversity', 'Climate Change', 0.6),
    ('Space', 'Mars', 0.8),
    ('Mars', 'Space', 0.8),
    ('Space', 'Tourism', 0.5),
    ('Tourism', 'Space', 0.5),
    ('Economy', 'Cryptocurrency', 0.6),
    ('Cryptocurrency', 'Economy', 0.6),
    ('Pandemic', 'Medicine', 0.7),
    ('Medicine', 'Pandemic', 0.7),
    ('Sports', 'Tourism', 0.4),
    ('Tourism', 'Sports', 0.4),
    ('Animals', 'Biodiversity', 0.8),
    ('Biodiversity', 'Animals', 0.8)
)
INSERT INTO tag_relations (source_tag_id, target_tag_id, strength)
SELECT s.id, t.id, trd.strength
FROM tag_relations_data trd
JOIN tags s ON trd.source_category = s.category
JOIN tags t ON trd.target_category = t.category;

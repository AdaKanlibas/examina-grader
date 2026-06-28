-- ============================================================
-- Examina — Seed IB AA topic tree
-- Run AFTER 001_initial_schema.sql
-- ============================================================

-- AA SL Topics
insert into public.topics (code, subject, paper, strand, title, sort_order) values
-- Algebra
('AA-SL-1',   'AA_SL', 'BOTH', 'Algebra',     'Algebra',                          100),
('AA-SL-1.1', 'AA_SL', 'BOTH', 'Algebra',     'Number & Algebra basics',          101),
('AA-SL-1.2', 'AA_SL', 'P1',   'Algebra',     'Arithmetic sequences & series',    102),
('AA-SL-1.3', 'AA_SL', 'P1',   'Algebra',     'Geometric sequences & series',     103),
('AA-SL-1.4', 'AA_SL', 'P1',   'Algebra',     'Financial applications (GDC)',     104),
('AA-SL-1.5', 'AA_SL', 'P1',   'Algebra',     'Exponents & logarithms',           105),
('AA-SL-1.6', 'AA_SL', 'P1',   'Algebra',     'Proof by deduction & contradiction',106),
('AA-SL-1.7', 'AA_SL', 'P1',   'Algebra',     'Laws of logarithms',               107),
('AA-SL-1.8', 'AA_SL', 'P1',   'Algebra',     'Sum of infinite geometric series', 108),
('AA-SL-1.9', 'AA_SL', 'P1',   'Algebra',     'Binomial theorem',                 109),
-- Functions
('AA-SL-2',   'AA_SL', 'BOTH', 'Functions',   'Functions',                        200),
('AA-SL-2.1', 'AA_SL', 'BOTH', 'Functions',   'Concept of a function',            201),
('AA-SL-2.2', 'AA_SL', 'BOTH', 'Functions',   'Linear functions & graph features',202),
('AA-SL-2.3', 'AA_SL', 'BOTH', 'Functions',   'Graph transformations',            203),
('AA-SL-2.4', 'AA_SL', 'BOTH', 'Functions',   'Composite & inverse functions',    204),
('AA-SL-2.5', 'AA_SL', 'BOTH', 'Functions',   'Quadratic functions & graphs',     205),
('AA-SL-2.6', 'AA_SL', 'BOTH', 'Functions',   'Quadratic equations',              206),
('AA-SL-2.7', 'AA_SL', 'BOTH', 'Functions',   'Rational functions',               207),
('AA-SL-2.8', 'AA_SL', 'BOTH', 'Functions',   'Exponential & logarithmic functions',208),
('AA-SL-2.9', 'AA_SL', 'BOTH', 'Functions',   'Sinusoidal models',                209),
('AA-SL-2.10','AA_SL', 'BOTH', 'Functions',   'Solving equations using GDC',      210),
-- Geometry & Trigonometry
('AA-SL-3',   'AA_SL', 'BOTH', 'Geometry',    'Geometry & Trigonometry',          300),
('AA-SL-3.1', 'AA_SL', 'BOTH', 'Geometry',    '3D geometry & distance',           301),
('AA-SL-3.2', 'AA_SL', 'BOTH', 'Geometry',    'Angles & arcs',                    302),
('AA-SL-3.3', 'AA_SL', 'BOTH', 'Geometry',    'Trigonometric ratios',             303),
('AA-SL-3.4', 'AA_SL', 'BOTH', 'Geometry',    'Sine & cosine rules',              304),
('AA-SL-3.5', 'AA_SL', 'BOTH', 'Geometry',    'Trigonometric equations',          305),
('AA-SL-3.6', 'AA_SL', 'P1',   'Geometry',    'Trigonometric identities',         306),
('AA-SL-3.7', 'AA_SL', 'BOTH', 'Geometry',    'Trigonometric functions & graphs', 307),
-- Statistics & Probability
('AA-SL-4',   'AA_SL', 'BOTH', 'Statistics',  'Statistics & Probability',         400),
('AA-SL-4.1', 'AA_SL', 'P2',   'Statistics',  'Descriptive statistics',           401),
('AA-SL-4.2', 'AA_SL', 'P2',   'Statistics',  'Measures of central tendency',     402),
('AA-SL-4.3', 'AA_SL', 'P2',   'Statistics',  'Grouped data & frequency',         403),
('AA-SL-4.4', 'AA_SL', 'P2',   'Statistics',  'Linear regression',                404),
('AA-SL-4.5', 'AA_SL', 'P2',   'Statistics',  'Probability basics',               405),
('AA-SL-4.6', 'AA_SL', 'P2',   'Statistics',  'Probability distributions',        406),
('AA-SL-4.7', 'AA_SL', 'P2',   'Statistics',  'Binomial distribution',            407),
('AA-SL-4.8', 'AA_SL', 'P2',   'Statistics',  'Normal distribution',              408),
('AA-SL-4.9', 'AA_SL', 'P2',   'Statistics',  'Hypothesis testing',               409),
-- Calculus
('AA-SL-5',   'AA_SL', 'BOTH', 'Calculus',    'Calculus',                         500),
('AA-SL-5.1', 'AA_SL', 'P1',   'Calculus',    'Introduction to differentiation',  501),
('AA-SL-5.2', 'AA_SL', 'P1',   'Calculus',    'Derivatives (power rule)',         502),
('AA-SL-5.3', 'AA_SL', 'BOTH', 'Calculus',    'Derivatives (product/quotient/chain)', 503),
('AA-SL-5.4', 'AA_SL', 'BOTH', 'Calculus',    'Applications of differentiation',  504),
('AA-SL-5.5', 'AA_SL', 'P1',   'Calculus',    'Integration (indefinite)',         505),
('AA-SL-5.6', 'AA_SL', 'P1',   'Calculus',    'Integration (further rules)',      506),
('AA-SL-5.7', 'AA_SL', 'BOTH', 'Calculus',    'Definite integrals & area',        507),
('AA-SL-5.8', 'AA_SL', 'P2',   'Calculus',    'Trapezoidal rule',                 508)
on conflict (code) do nothing;

-- AA HL Additional Topics
insert into public.topics (code, subject, paper, strand, title, sort_order) values
-- HL Algebra extensions
('AA-HL-1.10','AA_HL', 'P1',   'Algebra',     'Counting & permutations',          1100),
('AA-HL-1.11','AA_HL', 'P1',   'Algebra',     'Binomial theorem (fractional powers)',1101),
('AA-HL-1.12','AA_HL', 'P1',   'Algebra',     'Complex numbers',                  1102),
('AA-HL-1.13','AA_HL', 'P1',   'Algebra',     'Complex numbers (polar form)',     1103),
('AA-HL-1.14','AA_HL', 'P1',   'Algebra',     'Complex roots of polynomials',     1104),
('AA-HL-1.15','AA_HL', 'P1',   'Algebra',     'Proof by induction',               1105),
('AA-HL-1.16','AA_HL', 'P1',   'Algebra',     'Systems of linear equations',      1106),
-- HL Functions extensions
('AA-HL-2.11','AA_HL', 'P2',   'Functions',   'Factor theorem & polynomial division',2110),
('AA-HL-2.12','AA_HL', 'P2',   'Functions',   'Partial fractions',                2111),
('AA-HL-2.13','AA_HL', 'P2',   'Functions',   'Odd & even functions',             2112),
('AA-HL-2.14','AA_HL', 'P2',   'Functions',   'Reciprocal & rational functions (HL)',2113),
('AA-HL-2.15','AA_HL', 'P2',   'Functions',   'Absolute value functions',         2114),
('AA-HL-2.16','AA_HL', 'P2',   'Functions',   'Solving inequalities',             2115),
-- HL Geometry extensions
('AA-HL-3.8', 'AA_HL', 'P1',   'Geometry',    'Reciprocal trig functions',        3080),
('AA-HL-3.9', 'AA_HL', 'P1',   'Geometry',    'Compound angle identities',        3090),
('AA-HL-3.10','AA_HL', 'P1',   'Geometry',    'Double angle identities',          3100),
('AA-HL-3.11','AA_HL', 'BOTH', 'Geometry',    'Vectors',                          3110),
('AA-HL-3.12','AA_HL', 'BOTH', 'Geometry',    'Vector equations of lines & planes',3120),
('AA-HL-3.13','AA_HL', 'BOTH', 'Geometry',    'Intersections of lines & planes',  3130),
-- HL Statistics extensions
('AA-HL-4.10','AA_HL', 'P2',   'Statistics',  'Bayes theorem',                    4100),
('AA-HL-4.11','AA_HL', 'P2',   'Statistics',  'Variance & standard deviation (HL)',4110),
('AA-HL-4.12','AA_HL', 'P2',   'Statistics',  'Poisson distribution',             4120),
('AA-HL-4.13','AA_HL', 'P2',   'Statistics',  'Continuous random variables',      4130),
('AA-HL-4.14','AA_HL', 'P2',   'Statistics',  'Unbiased estimators',              4140),
('AA-HL-4.15','AA_HL', 'P2',   'Statistics',  'Confidence intervals (HL)',        4150),
('AA-HL-4.16','AA_HL', 'P2',   'Statistics',  'Statistical tests (HL)',           4160),
-- HL Calculus extensions
('AA-HL-5.9', 'AA_HL', 'BOTH', 'Calculus',    'Derivatives (HL — arcsin/arctan/implicit)', 5090),
('AA-HL-5.10','AA_HL', 'BOTH', 'Calculus',    'Related rates & optimisation (HL)', 5100),
('AA-HL-5.11','AA_HL', 'BOTH', 'Calculus',    'Proof by induction on derivatives', 5110),
('AA-HL-5.12','AA_HL', 'P2',   'Calculus',    'L Hopital rule & limits',          5120),
('AA-HL-5.13','AA_HL', 'P2',   'Calculus',    'Implicit differentiation',         5130),
('AA-HL-5.14','AA_HL', 'P2',   'Calculus',    'Integration by parts',             5140),
('AA-HL-5.15','AA_HL', 'P2',   'Calculus',    'Integration by substitution (HL)', 5150),
('AA-HL-5.16','AA_HL', 'P2',   'Calculus',    'Volumes of revolution',            5160),
('AA-HL-5.17','AA_HL', 'P2',   'Calculus',    'Differential equations',           5170),
('AA-HL-5.18','AA_HL', 'P2',   'Calculus',    'Maclaurin series',                 5180),
('AA-HL-5.19','AA_HL', 'P2',   'Calculus',    'Euler method',                     5190)
on conflict (code) do nothing;

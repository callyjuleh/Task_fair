const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());
app.use(express.json());

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'root',
    database: 'taskfair_db'
});

db.connect(err => {
    if (err) throw err;
    console.log('Connected to MySQL');
});


// ─────────────────────────────────────────────
//  AUTH
// ─────────────────────────────────────────────

// POST /register
app.post('/register', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required' });
    }

    const checkSql = 'SELECT id FROM users WHERE username = ?';
    db.query(checkSql, [username.trim()], (err, existing) => {
        if (err) return res.status(500).json(err);

        if (existing.length > 0) {
            return res.status(409).json({ message: 'Username already taken' });
        }

        // id is AUTO_INCREMENT — let MySQL handle it
        const insertSql = 'INSERT INTO users (username, password) VALUES (?, ?)';
        db.query(insertSql, [username.trim(), password], (err2, result) => {
            if (err2) return res.status(500).json(err2);
            res.status(201).json({
                message: 'Account created',
                user_id: result.insertId
            });
        });
    });
});

// POST /login
app.post('/login', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required' });
    }

    const sql = 'SELECT * FROM users WHERE username = ?';
    db.query(sql, [username.trim()], (err, result) => {
        if (err) return res.status(500).json(err);

        if (result.length === 0) {
            return res.status(401).json({ message: 'Invalid username or password' });
        }

        const user = result[0];

        // Plain text compare — matches existing users (admin123, juan123, etc.)
        if (password !== user.password) {
            return res.status(401).json({ message: 'Invalid username or password' });
        }

        res.json({
            message: 'Login successful',
            user: {
                id: user.id,
                username: user.username,
            }
        });
    });
});


// ─────────────────────────────────────────────
//  PROJECTS
// ─────────────────────────────────────────────

app.get('/projects', (req, res) => {
    const sql = 'SELECT * FROM projects ORDER BY created_at DESC';
    db.query(sql, (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

app.get('/projects/:id', (req, res) => {
    const sql = 'SELECT * FROM projects WHERE id = ?';
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        if (result.length === 0) return res.status(404).json({ message: 'Project not found' });
        res.json(result[0]);
    });
});

app.post('/projects', (req, res) => {
    const { project_name } = req.body;
    const id = uuidv4();
    const sql = `
        INSERT INTO projects (id, project_name, status, created_at, updated_at)
        VALUES (?, ?, 'setup', NOW(), NOW())
    `;
    db.query(sql, [id, project_name], (err) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({ message: 'Project created', project_id: id });
    });
});

app.put('/projects/:id/status', (req, res) => {
    const { status } = req.body;
    const validStatuses = ['setup', 'rating', 'computed', 'locked', 'done'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }
    const sql = 'UPDATE projects SET status = ?, updated_at = NOW() WHERE id = ?';
    db.query(sql, [status, req.params.id], (err) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Project status updated' });
    });
});

app.delete('/projects/:id', (req, res) => {
    const sql = 'DELETE FROM projects WHERE id = ?';
    db.query(sql, [req.params.id], (err) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Project deleted' });
    });
});


// ─────────────────────────────────────────────
//  MEMBERS
// ─────────────────────────────────────────────

app.get('/projects/:id/members', (req, res) => {
    const sql = 'SELECT * FROM members WHERE project_id = ? ORDER BY joined_at ASC';
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

app.post('/projects/:id/members', (req, res) => {
    const { name } = req.body;
    const id = uuidv4();
    const sql = `
        INSERT INTO members (id, project_id, name, has_submitted, fairness_vote, joined_at)
        VALUES (?, ?, ?, 0, NULL, NOW())
    `;
    db.query(sql, [id, req.params.id, name], (err) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({ message: 'Member added', member_id: id });
    });
});

app.put('/members/:id/vote', (req, res) => {
    const { fairness_vote } = req.body;
    const vote = fairness_vote ? 1 : 0;
    const sql = 'UPDATE members SET fairness_vote = ? WHERE id = ?';
    db.query(sql, [vote, req.params.id], (err) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Fairness vote submitted' });
    });
});

app.get('/projects/:id/votes', (req, res) => {
    const sql = `
        SELECT
            SUM(CASE WHEN fairness_vote = 1 THEN 1 ELSE 0 END) AS fair_votes,
            SUM(CASE WHEN fairness_vote = 0 THEN 1 ELSE 0 END) AS unfair_votes,
            SUM(CASE WHEN fairness_vote IS NULL THEN 1 ELSE 0 END) AS pending_votes
        FROM members WHERE project_id = ?
    `;
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result[0]);
    });
});

app.get('/projects/:id/all-submitted', (req, res) => {
    const sql = `
        SELECT COUNT(*) AS pending FROM members
        WHERE project_id = ? AND has_submitted = 0
    `;
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ all_submitted: result[0].pending === 0 });
    });
});


// ─────────────────────────────────────────────
//  TASKS
// ─────────────────────────────────────────────

app.get('/projects/:id/tasks', (req, res) => {
    const sql = `
        SELECT t.*, m.name AS assigned_to_name
        FROM tasks t
        LEFT JOIN members m ON t.assigned_to = m.id
        WHERE t.project_id = ?
    `;
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

app.post('/projects/:id/tasks', (req, res) => {
    const { task_name } = req.body;
    const id = uuidv4();
    const sql = `
        INSERT INTO tasks (id, project_id, task_name, assigned_to, status)
        VALUES (?, ?, ?, NULL, 'todo')
    `;
    db.query(sql, [id, req.params.id, task_name], (err) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({ message: 'Task added', task_id: id });
    });
});

app.post('/projects/:id/tasks/batch', (req, res) => {
    const { task_names } = req.body;
    if (!task_names || task_names.length === 0) {
        return res.status(400).json({ message: 'No tasks provided' });
    }
    const values = task_names.map(name => [uuidv4(), req.params.id, name, null, 'todo']);
    const sql = 'INSERT INTO tasks (id, project_id, task_name, assigned_to, status) VALUES ?';
    db.query(sql, [values], (err) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({ message: `${task_names.length} tasks added` });
    });
});

app.put('/tasks/:id/status', (req, res) => {
    const { status } = req.body;
    const validStatuses = ['todo', 'in_progress', 'done'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }
    const sql = 'UPDATE tasks SET status = ? WHERE id = ?';
    db.query(sql, [status, req.params.id], (err) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Task status updated' });
    });
});

app.delete('/tasks/:id', (req, res) => {
    const sql = 'DELETE FROM tasks WHERE id = ?';
    db.query(sql, [req.params.id], (err) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Task deleted' });
    });
});


// ─────────────────────────────────────────────
//  RATINGS
// ─────────────────────────────────────────────

app.post('/ratings', (req, res) => {
    const { member_id, ratings } = req.body;
    if (!member_id || !ratings) {
        return res.status(400).json({ message: 'member_id and ratings are required' });
    }
    const taskIds = Object.keys(ratings);
    let completed = 0;
    let hasError = false;

    taskIds.forEach(task_id => {
        const skill_rating = ratings[task_id];
        const checkSql = 'SELECT id FROM ratings WHERE member_id = ? AND task_id = ?';

        db.query(checkSql, [member_id, task_id], (err, existing) => {
            if (err) { hasError = true; return res.status(500).json(err); }

            let sql, params;
            if (existing.length > 0) {
                sql = 'UPDATE ratings SET skill_rating = ?, submitted_at = NOW() WHERE member_id = ? AND task_id = ?';
                params = [skill_rating, member_id, task_id];
            } else {
                sql = 'INSERT INTO ratings (id, member_id, task_id, skill_rating, submitted_at) VALUES (?, ?, ?, ?, NOW())';
                params = [uuidv4(), member_id, task_id, skill_rating];
            }

            db.query(sql, params, (err2) => {
                if (err2 && !hasError) { hasError = true; return res.status(500).json(err2); }
                completed++;
                if (completed === taskIds.length && !hasError) {
                    const markSql = 'UPDATE members SET has_submitted = 1 WHERE id = ?';
                    db.query(markSql, [member_id], (err3) => {
                        if (err3) return res.status(500).json(err3);
                        res.json({ message: 'Ratings submitted successfully' });
                    });
                }
            });
        });
    });
});

app.get('/projects/:id/ratings', (req, res) => {
    const sql = `
        SELECT r.member_id, r.task_id, r.skill_rating
        FROM ratings r
        JOIN members m ON r.member_id = m.id
        WHERE m.project_id = ?
    `;
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        const grouped = {};
        result.forEach(row => {
            if (!grouped[row.member_id]) grouped[row.member_id] = {};
            grouped[row.member_id][row.task_id] = row.skill_rating;
        });
        res.json(grouped);
    });
});


// ─────────────────────────────────────────────
//  RESULTS
// ─────────────────────────────────────────────

app.post('/results', (req, res) => {
    const { project_id, version, shapley_scores, assignments } = req.body;
    if (!project_id || !shapley_scores || !assignments) {
        return res.status(400).json({ message: 'Missing required fields' });
    }

    const rows = [];
    Object.keys(shapley_scores).forEach(member_id => {
        Object.keys(shapley_scores[member_id]).forEach(task_id => {
            const score = shapley_scores[member_id][task_id];
            const is_assigned = assignments[task_id] === member_id ? 1 : 0;
            rows.push([uuidv4(), project_id, member_id, task_id, score, is_assigned, version, new Date()]);
        });
    });

    const insertSql = `
        INSERT IGNORE INTO results
            (id, project_id, member_id, task_id, shapley_score, is_assigned, version, computed_at)
        VALUES ?
    `;

    db.query(insertSql, [rows], (err) => {
        if (err) return res.status(500).json(err);
        const taskIds = Object.keys(assignments);
        if (taskIds.length === 0) return res.json({ message: 'Results saved' });

        let done = 0;
        taskIds.forEach(task_id => {
            const member_id = assignments[task_id];
            db.query('UPDATE tasks SET assigned_to = ? WHERE id = ?', [member_id, task_id], (err2) => {
                if (err2) return res.status(500).json(err2);
                done++;
                if (done === taskIds.length) {
                    db.query(
                        "UPDATE projects SET status = 'computed', updated_at = NOW() WHERE id = ?",
                        [project_id],
                        (err3) => {
                            if (err3) return res.status(500).json(err3);
                            res.json({ message: 'Results saved and tasks assigned' });
                        }
                    );
                }
            });
        });
    });
});

app.get('/projects/:id/results', (req, res) => {
    const sql = `
        SELECT m.name AS member_name, m.id AS member_id,
               t.task_name, t.id AS task_id,
               r.shapley_score, r.is_assigned, r.version, r.computed_at
        FROM results r
        JOIN members m ON r.member_id = m.id
        JOIN tasks   t ON r.task_id   = t.id
        WHERE r.project_id = ?
        ORDER BY r.version DESC, t.task_name ASC, r.shapley_score DESC
    `;
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

app.get('/projects/:id/assignment', (req, res) => {
    const sql = `
        SELECT t.task_name, t.status AS task_status,
               m.name AS assigned_to, m.id AS member_id,
               r.shapley_score
        FROM tasks t
        LEFT JOIN members m ON t.assigned_to  = m.id
        LEFT JOIN results r ON r.task_id      = t.id
                           AND r.member_id    = t.assigned_to
                           AND r.is_assigned  = 1
        WHERE t.project_id = ?
        ORDER BY t.task_name ASC
    `;
    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});


app.listen(PORT, () => {
    console.log(`TaskFair server running on http://localhost:${PORT}`);
});
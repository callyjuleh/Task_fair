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



// GET all projects
app.get('/projects', (req, res) => {
    const sql = 'SELECT * FROM projects ORDER BY created_at DESC';

    db.query(sql, (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

// GET single project
app.get('/projects/:id', (req, res) => {
    const sql = 'SELECT * FROM projects WHERE id = ?';

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        if (result.length === 0) return res.status(404).json({ message: 'Project not found' });
        res.json(result[0]);
    });
});

// POST create project
app.post('/projects', (req, res) => {
    const { project_name } = req.body;
    const id = uuidv4();

    const sql = `
        INSERT INTO projects (id, project_name, status, created_at, updated_at)
        VALUES (?, ?, 'setup', NOW(), NOW())
    `;

    db.query(sql, [id, project_name], (err, result) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({
            message: 'Project created',
            project_id: id
        });
    });
});

// PUT update project status
app.put('/projects/:id/status', (req, res) => {
    const { status } = req.body;
    const validStatuses = ['setup', 'rating', 'computed', 'locked', 'done'];

    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }

    const sql = 'UPDATE projects SET status = ?, updated_at = NOW() WHERE id = ?';

    db.query(sql, [status, req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Project status updated' });
    });
});

// DELETE project (cascades to members, tasks, ratings, results)
app.delete('/projects/:id', (req, res) => {
    const sql = 'DELETE FROM projects WHERE id = ?';

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Project deleted' });
    });
});


// GET all members of a project
app.get('/projects/:id/members', (req, res) => {
    const sql = `
        SELECT * FROM members
        WHERE project_id = ?
        ORDER BY joined_at ASC
    `;

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

// POST add member to project
app.post('/projects/:id/members', (req, res) => {
    const { name } = req.body;
    const id = uuidv4();
    const project_id = req.params.id;

    const sql = `
        INSERT INTO members (id, project_id, name, has_submitted, fairness_vote, joined_at)
        VALUES (?, ?, ?, 0, NULL, NOW())
    `;

    db.query(sql, [id, project_id, name], (err, result) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({
            message: 'Member added',
            member_id: id
        });
    });
});

// PUT submit fairness vote
app.put('/members/:id/vote', (req, res) => {
    const { fairness_vote } = req.body;   // true or false from Flutter
    const vote = fairness_vote ? 1 : 0;

    const sql = 'UPDATE members SET fairness_vote = ? WHERE id = ?';

    db.query(sql, [vote, req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Fairness vote submitted' });
    });
});

// GET fairness vote count for a project
app.get('/projects/:id/votes', (req, res) => {
    const sql = `
        SELECT
            SUM(CASE WHEN fairness_vote = 1 THEN 1 ELSE 0 END) AS fair_votes,
            SUM(CASE WHEN fairness_vote = 0 THEN 1 ELSE 0 END) AS unfair_votes,
            SUM(CASE WHEN fairness_vote IS NULL THEN 1 ELSE 0 END) AS pending_votes
        FROM members
        WHERE project_id = ?
    `;

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result[0]);
    });
});

// GET check if all members submitted ratings
app.get('/projects/:id/all-submitted', (req, res) => {
    const sql = `
        SELECT COUNT(*) AS pending
        FROM members
        WHERE project_id = ? AND has_submitted = 0
    `;

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ all_submitted: result[0].pending === 0 });
    });
});


// GET all tasks of a project
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

// POST add single task
app.post('/projects/:id/tasks', (req, res) => {
    const { task_name } = req.body;
    const id = uuidv4();
    const project_id = req.params.id;

    const sql = `
        INSERT INTO tasks (id, project_id, task_name, assigned_to, status)
        VALUES (?, ?, ?, NULL, 'todo')
    `;

    db.query(sql, [id, project_id, task_name], (err, result) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({
            message: 'Task added',
            task_id: id
        });
    });
});

// POST add multiple tasks at once
app.post('/projects/:id/tasks/batch', (req, res) => {
    const { task_names } = req.body;   // array of strings
    const project_id = req.params.id;

    if (!task_names || task_names.length === 0) {
        return res.status(400).json({ message: 'No tasks provided' });
    }

    // Build batch insert values
    const values = task_names.map(name => [uuidv4(), project_id, name, null, 'todo']);
    const sql = `
        INSERT INTO tasks (id, project_id, task_name, assigned_to, status)
        VALUES ?
    `;

    db.query(sql, [values], (err, result) => {
        if (err) return res.status(500).json(err);
        res.status(201).json({
            message: `${task_names.length} tasks added`
        });
    });
});

// PUT update task status
app.put('/tasks/:id/status', (req, res) => {
    const { status } = req.body;
    const validStatuses = ['todo', 'in_progress', 'done'];

    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status' });
    }

    const sql = 'UPDATE tasks SET status = ? WHERE id = ?';

    db.query(sql, [status, req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Task status updated' });
    });
});

// DELETE task
app.delete('/tasks/:id', (req, res) => {
    const sql = 'DELETE FROM tasks WHERE id = ?';

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json({ message: 'Task deleted' });
    });
});


// POST submit all ratings for one member
// Body: { member_id, ratings: { task_id: 1-5, task_id: 1-5, ... } }
app.post('/ratings', (req, res) => {
    const { member_id, ratings } = req.body;

    if (!member_id || !ratings) {
        return res.status(400).json({ message: 'member_id and ratings are required' });
    }

    const taskIds = Object.keys(ratings);
    let completed = 0;
    let hasError = false;

    // Loop each task rating and INSERT or UPDATE
    taskIds.forEach(task_id => {
        const skill_rating = ratings[task_id];

        // Check if rating already exists
        const checkSql = `
            SELECT id FROM ratings
            WHERE member_id = ? AND task_id = ?
        `;

        db.query(checkSql, [member_id, task_id], (err, existing) => {
            if (err) {
                hasError = true;
                return res.status(500).json(err);
            }

            let sql, params;

            if (existing.length > 0) {
                // UPDATE existing rating
                sql = 'UPDATE ratings SET skill_rating = ?, submitted_at = NOW() WHERE member_id = ? AND task_id = ?';
                params = [skill_rating, member_id, task_id];
            } else {
                // INSERT new rating
                sql = 'INSERT INTO ratings (id, member_id, task_id, skill_rating, submitted_at) VALUES (?, ?, ?, ?, NOW())';
                params = [uuidv4(), member_id, task_id, skill_rating];
            }

            db.query(sql, params, (err2) => {
                if (err2 && !hasError) {
                    hasError = true;
                    return res.status(500).json(err2);
                }

                completed++;

                // After all ratings saved, mark member as submitted
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

// GET all ratings for a project (for Shapley engine in Flutter)
// Returns: { memberId: { taskId: rating } }
app.get('/projects/:id/ratings', (req, res) => {
    const sql = `
        SELECT r.member_id, r.task_id, r.skill_rating
        FROM ratings r
        JOIN members m ON r.member_id = m.id
        WHERE m.project_id = ?
    `;

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);

        // Group into nested object { memberId: { taskId: rating } }
        const grouped = {};
        result.forEach(row => {
            if (!grouped[row.member_id]) {
                grouped[row.member_id] = {};
            }
            grouped[row.member_id][row.task_id] = row.skill_rating;
        });

        res.json(grouped);
    });
});


// POST save Shapley results after computation in Flutter
// Body: { project_id, version, shapley_scores: { memberId: { taskId: score } }, assignments: { taskId: memberId } }
app.post('/results', (req, res) => {
    const { project_id, version, shapley_scores, assignments } = req.body;

    if (!project_id || !shapley_scores || !assignments) {
        return res.status(400).json({ message: 'Missing required fields' });
    }

    // Build all rows to insert
    const rows = [];
    Object.keys(shapley_scores).forEach(member_id => {
        Object.keys(shapley_scores[member_id]).forEach(task_id => {
            const score = shapley_scores[member_id][task_id];
            const is_assigned = assignments[task_id] === member_id ? 1 : 0;
            rows.push([uuidv4(), project_id, member_id, task_id, score, is_assigned, version]);
        });
    });

    const insertSql = `
        INSERT IGNORE INTO results
            (id, project_id, member_id, task_id, shapley_score, is_assigned, version, computed_at)
        VALUES ?
    `;

    // Append computed_at to each row
    const rowsWithDate = rows.map(r => [...r, new Date()]);

    db.query(insertSql, [rowsWithDate], (err) => {
        if (err) return res.status(500).json(err);

        // Update task assignments
        const taskIds = Object.keys(assignments);
        let done = 0;

        if (taskIds.length === 0) {
            return res.json({ message: 'Results saved' });
        }

        taskIds.forEach(task_id => {
            const member_id = assignments[task_id];
            const updateSql = 'UPDATE tasks SET assigned_to = ? WHERE id = ?';

            db.query(updateSql, [member_id, task_id], (err2) => {
                if (err2) return res.status(500).json(err2);
                done++;
                if (done === taskIds.length) {
                    // Update project status to computed
                    const statusSql = `
                        UPDATE projects SET status = 'computed', updated_at = NOW()
                        WHERE id = ?
                    `;
                    db.query(statusSql, [project_id], (err3) => {
                        if (err3) return res.status(500).json(err3);
                        res.json({ message: 'Results saved and tasks assigned' });
                    });
                }
            });
        });
    });
});

// GET results for a project (with member and task names)
app.get('/projects/:id/results', (req, res) => {
    const sql = `
        SELECT
            m.name          AS member_name,
            m.id            AS member_id,
            t.task_name,
            t.id            AS task_id,
            r.shapley_score,
            r.is_assigned,
            r.version,
            r.computed_at
        FROM results r
        JOIN members m ON r.member_id  = m.id
        JOIN tasks   t ON r.task_id    = t.id
        WHERE r.project_id = ?
        ORDER BY r.version DESC, t.task_name ASC, r.shapley_score DESC
    `;

    db.query(sql, [req.params.id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
});

// GET final assignment sheet for a project
app.get('/projects/:id/assignment', (req, res) => {
    const sql = `
        SELECT
            t.task_name,
            t.status        AS task_status,
            m.name          AS assigned_to,
            m.id            AS member_id,
            r.shapley_score
        FROM tasks t
        LEFT JOIN members m ON t.assigned_to = m.id
        LEFT JOIN results r ON r.task_id     = t.id
                           AND r.member_id   = t.assigned_to
                           AND r.is_assigned = 1
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
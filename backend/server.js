require('dotenv').config();
const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || 'root',
    database: process.env.DB_NAME || 'taskfair_db',
});

db.connect(err => {
    if (err) { console.error('DB connection failed:', err); process.exit(1); }
    console.log('Connected to MySQL');
});

app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/register', async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password)
        return res.status(400).json({ message: 'Username and password are required' });
    db.query('SELECT id FROM users WHERE username = ?', [username.trim()], async (err, existing) => {
        if (err) return res.status(500).json({ message: err.message });
        if (existing.length > 0)
            return res.status(409).json({ message: 'Username already taken' });
        try {
            const hashed = await bcrypt.hash(password, 10);
            db.query('INSERT INTO users (username, password) VALUES (?, ?)',
                [username.trim(), hashed],
                (err2, result) => {
                    if (err2) return res.status(500).json({ message: err2.message });
                    res.status(201).json({ message: 'Account created', user_id: result.insertId });
                });
        } catch (e) {
            res.status(500).json({ message: 'Hashing error', error: e.message });
        }
    });
});

app.post('/login', (req, res) => {
    const { username, password } = req.body;
    if (!username || !password)
        return res.status(400).json({ message: 'Username and password are required' });
    db.query('SELECT * FROM users WHERE username = ?', [username.trim()], async (err, result) => {
        if (err) return res.status(500).json({ message: err.message });
        if (result.length === 0)
            return res.status(401).json({ message: 'Invalid username or password' });
        const user = result[0];
        try {
            const match = await bcrypt.compare(password, user.password);
            if (!match)
                return res.status(401).json({ message: 'Invalid username or password' });
            res.json({ message: 'Login successful', user: { id: user.id, username: user.username } });
        } catch (e) {
            res.status(500).json({ message: 'Auth error', error: e.message });
        }
    });
});

// ── PROJECTS ──────────────────────────────────────────────────────
// Only return projects that have NOT been soft-deleted
app.get('/projects', (req, res) => {
    db.query('SELECT * FROM projects WHERE deleted_at IS NULL ORDER BY created_at DESC', (err, result) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json(result);
    });
});

app.get('/projects/:id', (req, res) => {
    db.query('SELECT * FROM projects WHERE id = ? AND deleted_at IS NULL', [req.params.id], (err, result) => {
        if (err) return res.status(500).json({ message: err.message });
        if (result.length === 0) return res.status(404).json({ message: 'Project not found' });
        res.json(result[0]);
    });
});

app.get('/projects/:id/summary', (req, res) => {
    const pid = req.params.id;
    db.query('SELECT * FROM projects WHERE id = ? AND deleted_at IS NULL', [pid], (e1, proj) => {
        if (e1 || proj.length === 0) return res.status(404).json({ message: 'Project not found' });
        db.query('SELECT id, name, has_submitted FROM members WHERE project_id = ? AND deleted_at IS NULL', [pid], (e2, members) => {
            if (e2) return res.status(500).json({ message: e2.message });
            db.query(
                `SELECT t.id, t.task_name, t.status, m.name AS assigned_to_name
                 FROM tasks t LEFT JOIN members m ON t.assigned_to = m.id
                 WHERE t.project_id = ? AND t.deleted_at IS NULL`, [pid], (e3, tasks) => {
                if (e3) return res.status(500).json({ message: e3.message });
                res.json({ project: proj[0], members, tasks, votes: { fair_votes: 0, unfair_votes: 0, pending_votes: members.length } });
            });
        });
    });
});

app.post('/projects', (req, res) => {
    const { project_name } = req.body;
    if (!project_name) return res.status(400).json({ message: 'project_name is required' });
    const id = uuidv4();
    db.query(
        "INSERT INTO projects (id, project_name, status, created_at, updated_at) VALUES (?, ?, 'setup', NOW(), NOW())",
        [id, project_name],
        (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.status(201).json({ message: 'Project created', project_id: id });
        }
    );
});

app.put('/projects/:id', (req, res) => {
    const { project_name } = req.body;
    if (!project_name) return res.status(400).json({ message: 'project_name is required' });
    db.query('UPDATE projects SET project_name = ?, updated_at = NOW() WHERE id = ? AND deleted_at IS NULL',
        [project_name.trim(), req.params.id], (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json({ message: 'Project updated' });
        });
});

app.put('/projects/:id/status', (req, res) => {
    const { status } = req.body;
    const valid = ['setup', 'rating', 'computed', 'locked', 'done'];
    if (!valid.includes(status))
        return res.status(400).json({ message: 'Invalid status' });
    db.query('UPDATE projects SET status = ?, updated_at = NOW() WHERE id = ? AND deleted_at IS NULL',
        [status, req.params.id], (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json({ message: 'Project status updated' });
        });
});

// SOFT DELETE — project stays in SQL with deleted_at timestamp
app.delete('/projects/:id', (req, res) => {
    db.query('UPDATE projects SET deleted_at = NOW(), updated_at = NOW() WHERE id = ?',
        [req.params.id], (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json({ message: 'Project deleted' });
        });
});

// ── MEMBERS ───────────────────────────────────────────────────────
// Only return active (non-deleted) members
app.get('/projects/:id/members', (req, res) => {
    db.query('SELECT * FROM members WHERE project_id = ? AND deleted_at IS NULL ORDER BY joined_at ASC',
        [req.params.id], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json(result);
        });
});

app.post('/projects/:id/members', (req, res) => {
    const { name } = req.body;
    if (!name) return res.status(400).json({ message: 'name is required' });
    const id = uuidv4();
    db.query(
        'INSERT INTO members (id, project_id, name, has_submitted, joined_at) VALUES (?, ?, ?, 0, NOW())',
        [id, req.params.id, name],
        (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.status(201).json({ message: 'Member added', member_id: id });
        }
    );
});

// SOFT DELETE — member stays in SQL with deleted_at timestamp
app.delete('/members/:id', (req, res) => {
    db.query('UPDATE members SET deleted_at = NOW() WHERE id = ?', [req.params.id], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json({ message: 'Member removed' });
    });
});

app.put('/members/:id/vote', (req, res) => {
    res.json({ message: 'Fairness vote not supported' });
});

app.get('/projects/:id/votes', (req, res) => {
    db.query(
        'SELECT COUNT(*) AS total FROM members WHERE project_id = ? AND deleted_at IS NULL',
        [req.params.id], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json({ fair_votes: 0, unfair_votes: 0, pending_votes: result[0].total });
        });
});

app.get('/projects/:id/all-submitted', (req, res) => {
    db.query('SELECT COUNT(*) AS pending FROM members WHERE project_id = ? AND has_submitted = 0 AND deleted_at IS NULL',
        [req.params.id], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json({ all_submitted: result[0].pending === 0 });
        });
});

// ── TASKS ─────────────────────────────────────────────────────────
// Only return active (non-deleted) tasks
app.get('/projects/:id/tasks', (req, res) => {
    db.query(
        `SELECT t.*, m.name AS assigned_to_name
         FROM tasks t LEFT JOIN members m ON t.assigned_to = m.id
         WHERE t.project_id = ? AND t.deleted_at IS NULL`,
        [req.params.id], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json(result);
        });
});

app.post('/projects/:id/tasks', (req, res) => {
    const { task_name } = req.body;
    if (!task_name) return res.status(400).json({ message: 'task_name is required' });
    const id = uuidv4();
    db.query(
        "INSERT INTO tasks (id, project_id, task_name, assigned_to, status, difficulty) VALUES (?, ?, ?, NULL, 'in_progress', NULL)",
        [id, req.params.id, task_name],
        (err) => {
            if (err) {
                console.error('POST /tasks error:', err);
                return res.status(500).json({ message: err.message });
            }
            res.status(201).json({ message: 'Task added', task_id: id });
        }
    );
});

app.post('/projects/:id/tasks/batch', (req, res) => {
    const { task_names } = req.body;
    if (!task_names || task_names.length === 0)
        return res.status(400).json({ message: 'No tasks provided' });
    const values = task_names.map(name => [uuidv4(), req.params.id, name, null, 'in_progress', null]);
    db.query(
        'INSERT INTO tasks (id, project_id, task_name, assigned_to, status, difficulty) VALUES ?',
        [values], (err) => {
            if (err) return res.status(500).json({ message: err.message });
            res.status(201).json({ message: `${task_names.length} tasks added` });
        }
    );
});

app.put('/tasks/:id', (req, res) => {
    const { task_name, difficulty } = req.body;
    if (task_name === undefined && difficulty === undefined)
        return res.status(400).json({ message: 'task_name or difficulty is required' });

    const fields = [];
    const values = [];
    if (task_name !== undefined) { fields.push('task_name = ?'); values.push(task_name); }
    if (difficulty !== undefined) { fields.push('difficulty = ?'); values.push(difficulty); }
    values.push(req.params.id);

    db.query(`UPDATE tasks SET ${fields.join(', ')} WHERE id = ? AND deleted_at IS NULL`, values, (err) => {
        if (err) {
            console.error('PUT /tasks/:id error:', err);
            return res.status(500).json({ message: err.message });
        }
        res.json({ message: 'Task updated' });
    });
});

app.put('/tasks/:id/status', (req, res) => {
    const { status } = req.body;
    const valid = ['todo', 'in_progress', 'completed'];
    if (!valid.includes(status))
        return res.status(400).json({ message: 'Invalid status' });
    db.query('UPDATE tasks SET status = ? WHERE id = ? AND deleted_at IS NULL', [status, req.params.id], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json({ message: 'Task status updated' });
    });
});

// SOFT DELETE — task stays in SQL with deleted_at timestamp
app.delete('/tasks/:id', (req, res) => {
    db.query('UPDATE tasks SET deleted_at = NOW() WHERE id = ?', [req.params.id], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        res.json({ message: 'Task deleted' });
    });
});

// ── RATINGS ───────────────────────────────────────────────────────
app.post('/ratings', (req, res) => {
    const { member_id, ratings } = req.body;
    if (!member_id || !ratings)
        return res.status(400).json({ message: 'member_id and ratings are required' });

    const taskIds = Object.keys(ratings);
    if (taskIds.length === 0)
        return res.status(400).json({ message: 'ratings object is empty' });

    const upsertOne = (task_id, skill_rating) => new Promise((resolve, reject) => {
        db.query('SELECT id FROM ratings WHERE member_id = ? AND task_id = ?',
            [member_id, task_id], (err, existing) => {
                if (err) return reject(err);
                const [sql, params] = existing.length > 0
                    ? ['UPDATE ratings SET skill_rating = ?, submitted_at = NOW() WHERE member_id = ? AND task_id = ?',
                        [skill_rating, member_id, task_id]]
                    : ['INSERT INTO ratings (id, member_id, task_id, skill_rating, submitted_at) VALUES (?, ?, ?, ?, NOW())',
                        [uuidv4(), member_id, task_id, skill_rating]];
                db.query(sql, params, (err2) => {
                    if (err2) return reject(err2);
                    resolve();
                });
            });
    });

    Promise.all(taskIds.map(tid => upsertOne(tid, ratings[tid])))
        .then(() => {
            db.query('UPDATE members SET has_submitted = 1 WHERE id = ?', [member_id], (err) => {
                if (err) return res.status(500).json({ message: err.message });
                res.json({ message: 'Ratings submitted successfully' });
            });
        })
        .catch(err => {
            console.error('POST /ratings error:', err);
            res.status(500).json({ message: err.message });
        });
});

app.get('/projects/:id/ratings', (req, res) => {
    db.query(
        `SELECT r.member_id, r.task_id, r.skill_rating
         FROM ratings r JOIN members m ON r.member_id = m.id
         WHERE m.project_id = ? AND m.deleted_at IS NULL`,
        [req.params.id], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            const grouped = {};
            result.forEach(row => {
                if (!grouped[row.member_id]) grouped[row.member_id] = {};
                grouped[row.member_id][row.task_id] = row.skill_rating;
            });
            res.json(grouped);
        });
});

app.delete('/ratings/:member_id', (req, res) => {
    db.query('DELETE FROM ratings WHERE member_id = ?', [req.params.member_id], (err) => {
        if (err) return res.status(500).json({ message: err.message });
        db.query('UPDATE members SET has_submitted = 0 WHERE id = ?',
            [req.params.member_id], (err2) => {
                if (err2) return res.status(500).json({ message: err2.message });
                res.json({ message: 'Ratings reset for member' });
            });
    });
});

// ── SHAPLEY ───────────────────────────────────────────────────────
function factorial(n) {
    if (n <= 1) return 1;
    let r = 1;
    for (let i = 2; i <= n; i++) r *= i;
    return r;
}

function computeShapley(membersArr, tasksArr, ratingsMatrix, difficultiesArr) {
    const n = membersArr.length;
    const t = tasksArr.length;
    const shapleyScores = Array.from({ length: n }, () => Array(t).fill(0));

    for (let taskIdx = 0; taskIdx < t; taskIdx++) {
        const diff = (difficultiesArr && difficultiesArr[taskIdx]) ? difficultiesArr[taskIdx] : 1;
        const r = membersArr.map((_, mi) => ratingsMatrix[mi][taskIdx] * diff);
        const v = (subset) => {
            if (subset.length === 0) return 0;
            return subset.reduce((sum, mi) => sum + r[mi], 0) / subset.length;
        };
        for (let i = 0; i < n; i++) {
            let phi = 0;
            const others = membersArr.map((_, m) => m).filter(m => m !== i);
            const numSubsets = 1 << others.length;
            for (let mask = 0; mask < numSubsets; mask++) {
                const S = [];
                for (let bit = 0; bit < others.length; bit++) {
                    if ((mask >> bit) & 1) S.push(others[bit]);
                }
                const s = S.length;
                const weight = (factorial(s) * factorial(n - s - 1)) / factorial(n);
                phi += weight * (v([...S, i]) - v(S));
            }
            shapleyScores[i][taskIdx] = Math.round(phi * 100) / 100;
        }
    }
    return shapleyScores;
}

function assignTasks(shapleyScores, membersArr, tasksArr) {
    const n = membersArr.length;
    const t = tasksArr.length;
    const load = Array(n).fill(0);

    const taskOrder = Array.from({ length: t }, (_, i) => i).sort((a, b) => {
        const scoresA = membersArr.map((_, m) => shapleyScores[m][a]).sort((x, y) => y - x);
        const scoresB = membersArr.map((_, m) => shapleyScores[m][b]).sort((x, y) => y - x);
        const spreadA = scoresA.length > 1 ? scoresA[0] - scoresA[1] : scoresA[0];
        const spreadB = scoresB.length > 1 ? scoresB[0] - scoresB[1] : scoresB[0];
        return spreadB - spreadA;
    });

    const assignments = Array.from({ length: t }, () => []);
    const assignedOnce = new Set();

    for (const taskIdx of taskOrder) {
        const candidates = Array.from({ length: n }, (_, m) => m)
            .sort((a, b) => {
                const diff = shapleyScores[b][taskIdx] - shapleyScores[a][taskIdx];
                return diff !== 0 ? diff : load[a] - load[b];
            });
        const chosen = candidates.find(m => !assignedOnce.has(m)) ?? candidates[0];
        assignments[taskIdx].push(chosen);
        assignedOnce.add(chosen);
        load[chosen]++;
    }

    const unassigned = Array.from({ length: n }, (_, m) => m).filter(m => !assignedOnce.has(m));
    for (const m of unassigned) {
        let bestTask = 0;
        let bestFit = -Infinity;
        for (let taskIdx = 0; taskIdx < t; taskIdx++) {
            const currentScore = assignments[taskIdx].length > 0
                ? shapleyScores[assignments[taskIdx][0]][taskIdx] : 0;
            const fit = shapleyScores[m][taskIdx] - currentScore * 0.5;
            if (fit > bestFit) { bestFit = fit; bestTask = taskIdx; }
        }
        assignments[bestTask].push(m);
        load[m]++;
    }

    return assignments;
}

app.post('/compute-shapley', (req, res) => {
    const { project_id } = req.body;
    if (!project_id)
        return res.status(400).json({ message: 'project_id is required' });

    // Only compute using active (non-deleted) members and tasks
    db.query('SELECT id, name FROM members WHERE project_id = ? AND deleted_at IS NULL ORDER BY joined_at ASC',
        [project_id], (err, members) => {
            if (err) return res.status(500).json({ message: err.message });
            if (members.length === 0)
                return res.status(400).json({ message: 'No members found' });

            db.query('SELECT id, task_name, difficulty FROM tasks WHERE project_id = ? AND deleted_at IS NULL ORDER BY task_name ASC',
                [project_id], (err2, tasks) => {
                    if (err2) return res.status(500).json({ message: err2.message });
                    if (tasks.length === 0)
                        return res.status(400).json({ message: 'No tasks found' });

                    db.query(
                        `SELECT r.member_id, r.task_id, r.skill_rating
                         FROM ratings r JOIN members m ON r.member_id = m.id
                         WHERE m.project_id = ? AND m.deleted_at IS NULL`,
                        [project_id], (err3, ratingsRows) => {
                            if (err3) return res.status(500).json({ message: err3.message });

                            const memberIds = members.map(m => m.id);
                            const taskIds = tasks.map(t => t.id);
                            const difficulties = tasks.map(t => t.difficulty || 1);
                            const ratingsMatrix = Array.from({ length: members.length },
                                () => Array(tasks.length).fill(0));
                            ratingsRows.forEach(row => {
                                const mi = memberIds.indexOf(row.member_id);
                                const ti = taskIds.indexOf(row.task_id);
                                if (mi !== -1 && ti !== -1) ratingsMatrix[mi][ti] = row.skill_rating;
                            });

                            const shapleyScores = computeShapley(members, tasks, ratingsMatrix, difficulties);
                            const assignments = assignTasks(shapleyScores, members, tasks);

                            const shapleyMap = {};
                            const assignmentMap = {};
                            members.forEach((member, mi) => {
                                shapleyMap[member.id] = {};
                                tasks.forEach((task, ti) => {
                                    shapleyMap[member.id][task.id] = shapleyScores[mi][ti];
                                });
                            });
                            tasks.forEach((task, ti) => {
                                if (assignments[ti].length > 0)
                                    assignmentMap[task.id] = members[assignments[ti][0]].id;
                            });

                            const rows = [];
                            members.forEach(member => {
                                tasks.forEach(task => {
                                    const score = shapleyMap[member.id][task.id];
                                    const is_assigned = assignmentMap[task.id] === member.id ? 1 : 0;
                                    rows.push([uuidv4(), project_id, member.id, task.id, score, is_assigned, 1, new Date()]);
                                });
                            });

                            db.query(
                                'INSERT IGNORE INTO results (id, project_id, member_id, task_id, shapley_score, is_assigned, version, computed_at) VALUES ?',
                                [rows], (err4) => {
                                    if (err4) return res.status(500).json({ message: err4.message });

                                    const taskEntries = Object.entries(assignmentMap);
                                    if (taskEntries.length === 0) {
                                        return db.query(
                                            "UPDATE projects SET status='computed', updated_at=NOW() WHERE id=?",
                                            [project_id],
                                            () => res.json({ message: 'Shapley computed', shapley_scores: shapleyMap, assignments: assignmentMap })
                                        );
                                    }

                                    let done = 0;
                                    taskEntries.forEach(([task_id, member_id]) => {
                                        db.query('UPDATE tasks SET assigned_to = ? WHERE id = ?',
                                            [member_id, task_id], (err5) => {
                                                if (err5) return res.status(500).json({ message: err5.message });
                                                done++;
                                                if (done === taskEntries.length) {
                                                    db.query(
                                                        "UPDATE projects SET status='computed', updated_at=NOW() WHERE id=?",
                                                        [project_id], (err6) => {
                                                            if (err6) return res.status(500).json({ message: err6.message });
                                                            res.json({
                                                                message: 'Shapley computed and tasks assigned',
                                                                shapley_scores: shapleyMap,
                                                                assignments: assignmentMap,
                                                            });
                                                        });
                                                }
                                            });
                                    });
                                });
                        });
                });
        });
});

// ── RESULTS ───────────────────────────────────────────────────────
app.post('/results', (req, res) => {
    const { project_id, version, shapley_scores, assignments } = req.body;
    if (!project_id || !shapley_scores || !assignments)
        return res.status(400).json({ message: 'Missing required fields' });

    const rows = [];
    Object.keys(shapley_scores).forEach(member_id => {
        Object.keys(shapley_scores[member_id]).forEach(task_id => {
            const score = shapley_scores[member_id][task_id];
            const is_assigned = assignments[task_id] === member_id ? 1 : 0;
            rows.push([uuidv4(), project_id, member_id, task_id, score, is_assigned, version || 1, new Date()]);
        });
    });

    db.query(
        'INSERT IGNORE INTO results (id, project_id, member_id, task_id, shapley_score, is_assigned, version, computed_at) VALUES ?',
        [rows], (err) => {
            if (err) return res.status(500).json({ message: err.message });
            const taskEntries = Object.entries(assignments);
            if (taskEntries.length === 0)
                return res.json({ message: 'Results saved' });
            let done = 0;
            taskEntries.forEach(([task_id, member_id]) => {
                db.query('UPDATE tasks SET assigned_to = ? WHERE id = ?', [member_id, task_id], (err2) => {
                    if (err2) return res.status(500).json({ message: err2.message });
                    done++;
                    if (done === taskEntries.length) {
                        db.query("UPDATE projects SET status='computed', updated_at=NOW() WHERE id=?",
                            [project_id], (err3) => {
                                if (err3) return res.status(500).json({ message: err3.message });
                                res.json({ message: 'Results saved and tasks assigned' });
                            });
                    }
                });
            });
        });
});

app.get('/projects/:id/results', (req, res) => {
    db.query(
        `SELECT m.name AS member_name, m.id AS member_id,
                t.task_name, t.id AS task_id,
                r.shapley_score, r.is_assigned, r.version, r.computed_at
         FROM results r
         JOIN members m ON r.member_id = m.id
         JOIN tasks   t ON r.task_id   = t.id
         WHERE r.project_id = ?
         ORDER BY r.version DESC, t.task_name ASC, r.shapley_score DESC`,
        [req.params.id], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json(result);
        });
});

app.get('/projects/:id/assignment', (req, res) => {
    db.query(
        `SELECT t.task_name, t.status AS task_status,
                m.name AS assigned_to, m.id AS member_id,
                r.shapley_score
         FROM tasks t
         LEFT JOIN members m ON t.assigned_to = m.id
         LEFT JOIN results r ON r.task_id=t.id AND r.member_id=t.assigned_to AND r.is_assigned=1
         WHERE t.project_id = ? AND t.deleted_at IS NULL
         ORDER BY t.task_name ASC`,
        [req.params.id], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json(result);
        });
});

// ── MY PROJECTS ───────────────────────────────────────────────────
app.get('/my-projects/:username', (req, res) => {
    const username = req.params.username;
    db.query(
        `SELECT DISTINCT p.id, p.project_name, p.status, p.created_at
         FROM projects p
         JOIN members m ON m.project_id = p.id
         WHERE m.name = ? AND p.deleted_at IS NULL AND m.deleted_at IS NULL
         ORDER BY p.created_at DESC`,
        [username], (err, result) => {
            if (err) return res.status(500).json({ message: err.message });
            res.json(result);
        }
    );
});

app.listen(PORT, () => {
    console.log(`TaskFair server running on http://localhost:${PORT}`);
});
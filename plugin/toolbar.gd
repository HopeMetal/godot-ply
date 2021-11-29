@tool
extends Object

const SelectionMode = preload("../utils/selection_mode.gd")
const Extrude = preload("../resources/extrude.gd")
const Subdivide = preload("../resources/subdivide.gd")
const Loop = preload("../resources/loop.gd")
const Collapse = preload("../resources/collapse.gd")
const Connect = preload("../resources/connect.gd")
const Generate = preload("../resources/generate.gd")

var toolbar = preload("../gui/toolbar/toolbar.tscn").instantiate()

var _plugin

func _init(plugin):
	_plugin = plugin

func _connect_toolbar_handlers():
	if toolbar.face_select_loop_1.button_up.is_connected(self._generate_cube):
		return

	toolbar.generate_plane.connect(self._generate_plane)
	toolbar.generate_cube.connect(self._generate_cube)

	toolbar.face_select_loop_1.button_up.connect(self._face_select_loop.bind(0))
	toolbar.face_select_loop_2.button_up.connect(self._face_select_loop.bind(1))
	toolbar.face_extrude.button_up.connect(self._face_extrude)
	toolbar.face_connect.button_up.connect(self._face_connect)
	toolbar.set_face_surface.connect(self._set_face_surface)

	toolbar.edge_select_loop.button_up.connect(self._edge_select_loop)
	toolbar.edge_cut_loop.button_up.connect(self._edge_cut_loop)
	toolbar.edge_subdivide.button_up.connect(self._edge_subdivide)
	toolbar.edge_collapse.button_up.connect(self._edge_collapse)


func startup():
	_plugin.add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
	toolbar.visible = false
	_connect_toolbar_handlers()
	_plugin.selector.selection_changed.connect(self._on_selection_changed)

func teardown():
	toolbar.visible = false
	_plugin.remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , toolbar)
	_plugin.selector.selection_changed.disconnect(self._on_selection_changed)
	toolbar.queue_free()

func in_transform_mode():
	return toolbar.transform_toggle.pressed

func _on_selection_changed(mode, editing, _selection):
	if editing:
		toolbar.visible = true
	else:
		toolbar.visible = false

func _generate_cube():
	if not _plugin.selector.editing:
		return
	var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
	var vertexes = [Vector3(-0.5,-0.5,-0.5), Vector3(0.5,-0.5,-0.5), Vector3(0.5,-0.5,0.5), Vector3(-0.5,-0.5,0.5)]
	Generate.nGon(_plugin.selector.editing.ply_mesh, vertexes)
	Extrude.faces(_plugin.selector.editing.ply_mesh, [0])
	_plugin.selector.editing.ply_mesh.commit_edit("Generate Cube", _plugin.undo_redo, pre_edit)

func _generate_plane():
	if not _plugin.selector.editing:
		return

	var vertexes = [Vector3(-0.5,0,-0.5), Vector3(0.5,0,-0.5), Vector3(0.5,0,0.5), Vector3(-0.5,0,0.5)]
	Generate.nGon(_plugin.selector.editing.ply_mesh, vertexes, _plugin.undo_redo, "Generate Plane")

func _face_select_loop(offset):
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() != 1:
		return
	var loop = Loop.get_face_loop(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], offset)[0]
	_plugin.selector.set_selection(loop)

func _face_extrude():
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() == 0:
		return
	Extrude.faces(_plugin.selector.editing.ply_mesh, _plugin.selector.selection, _plugin.undo_redo, 1)

func _face_connect():
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() != 2:
		return
	Connect.faces(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.selector.selection[1], _plugin.undo_redo)

func _set_face_surface(s):
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.FACE or _plugin.selector.selection.size() == 0:
		return
	var pre_edit = _plugin.selector.editing.ply_mesh.begin_edit()
	for f_idx in _plugin.selector.selection:
		_plugin.selector.editing.ply_mesh.set_face_surface(f_idx, s)
	_plugin.selector.editing.ply_mesh.commit_edit("Paint Face", _plugin.undo_redo, pre_edit)

func _edge_select_loop():
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
		return
	var loop = Loop.get_edge_loop(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0])
	_plugin.selector.set_selection(loop)

func _edge_cut_loop():
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
		return
	Loop.edge_cut(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.undo_redo)

func _edge_subdivide():
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() != 1:
		return
	Subdivide.edge(_plugin.selector.editing.ply_mesh, _plugin.selector.selection[0], _plugin.undo_redo)

func _edge_collapse():
	if not _plugin.selector.editing or _plugin.selector.mode != SelectionMode.EDGE or _plugin.selector.selection.size() == 0:
		return
	if Collapse.edges(_plugin.selector.editing.ply_mesh, _plugin.selector.selection, _plugin.undo_redo):
		_plugin.selector.set_selection([])

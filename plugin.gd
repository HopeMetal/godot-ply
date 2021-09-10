tool
extends EditorPlugin

"""
██████╗ ██████╗ ███████╗██╗      ██████╗  █████╗ ██████╗ ███████╗
██╔══██╗██╔══██╗██╔════╝██║     ██╔═══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝██████╔╝█████╗  ██║     ██║   ██║███████║██║  ██║███████╗
██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║██╔══██║██║  ██║╚════██║
██║     ██║  ██║███████╗███████╗╚██████╔╝██║  ██║██████╔╝███████║
╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝
"""
const Selector = preload("./plugin/selector.gd")
const SpatialEditor = preload("./plugin/spatial_editor.gd")

const SelectionMode = preload("./utils/selection_mode.gd")
const PlyNode = preload("./nodes/ply.gd")
const Face = preload("./gui/face.gd")
const Edge = preload("./gui/edge.gd")
const Editor = preload("./gui/editor.gd")
const Handle = preload("./plugin/handle.gd")

func get_plugin_name():
    return "Ply"

const DEBUG = true
var hotbar = preload("./gui/hotbar.tscn").instance()

var spatial_editor = null
var selector = null

var undo_redo = null

"""
███████╗████████╗ █████╗ ██████╗ ████████╗██╗   ██╗██████╗   ██╗████████╗███████╗ █████╗ ██████╗ ██████╗  ██████╗ ██╗    ██╗███╗   ██╗
██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝██║   ██║██╔══██╗ ██╔╝╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║    ██║████╗  ██║
███████╗   ██║   ███████║██████╔╝   ██║   ██║   ██║██████╔╝██╔╝    ██║   █████╗  ███████║██████╔╝██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║
╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ██║   ██║██╔═══╝██╔╝     ██║   ██╔══╝  ██╔══██║██╔══██╗██║  ██║██║   ██║██║███╗██║██║╚██╗██║
███████║   ██║   ██║  ██║██║  ██║   ██║   ╚██████╔╝██║   ██╔╝      ██║   ███████╗██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝   ╚═╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝
"""
func _enter_tree() -> void:
    add_custom_type("PlyInstance", "MeshInstance", preload("./nodes/ply.gd"), preload("./icon.png"))
    undo_redo = get_undo_redo()

    hotbar.hide()

    add_control_to_container(CONTAINER_SPATIAL_EDITOR_SIDE_LEFT , hotbar)
    
    selector = Selector.new(self)
    selector.startup()
    selector.connect("selection_changed", self, "_on_selection_changed")
    spatial_editor = SpatialEditor.new(self)
    spatial_editor.startup()

    set_input_event_forwarding_always_enabled()

func _exit_tree() -> void:
    remove_custom_type("PlyInstance")

    spatial_editor.teardown()
    selector.teardown()

    hotbar.queue_free()

    disconnect("scene_changed", self, "_on_scene_change")

func get_state():
    return { 
        "selector": selector.get_state(),
        "spatial_editor": spatial_editor.get_state()
    }

func set_state(state):
    selector.set_state(state.get("selector"))
    spatial_editor.set_state(state.get("spatial_editor"))

"""
██╗  ██╗ ██████╗ ████████╗██████╗  █████╗ ██████╗     ██╗     ██╗███████╗████████╗███████╗███╗   ██╗███████╗██████╗ ███████╗
██║  ██║██╔═══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗    ██║     ██║██╔════╝╚══██╔══╝██╔════╝████╗  ██║██╔════╝██╔══██╗██╔════╝
███████║██║   ██║   ██║   ██████╔╝███████║██████╔╝    ██║     ██║███████╗   ██║   █████╗  ██╔██╗ ██║█████╗  ██████╔╝███████╗
██╔══██║██║   ██║   ██║   ██╔══██╗██╔══██║██╔══██╗    ██║     ██║╚════██║   ██║   ██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗╚════██║
██║  ██║╚██████╔╝   ██║   ██████╔╝██║  ██║██║  ██║    ███████╗██║███████║   ██║   ███████╗██║ ╚████║███████╗██║  ██║███████║
╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝
"""
func _generate_cube():
    if not selector.editing:
        return
    var pre_edit = selector.editing.ply_mesh.begin_edit()
    _generate_plane(false)
    Extrude.face(selector.editing.ply_mesh, 0)
    selector.editing.ply_mesh.commit_edit("Generate Cube", undo_redo, pre_edit)

func _generate_plane(undoable=true):
    if not selector.editing:
        return

    var vertexes = [Vector3(0,0,0), Vector3(1,0,0), Vector3(0,0,1), Vector3(1,0,1)]
    var vertex_edges = [0, 0, 3, 3]
    var edge_vertexes = [ 0, 1, 1, 3, 3, 2, 2, 0 ]
    var face_edges = [0, 0]
    var edge_faces = [ 1 , 0, 1 , 0, 1 , 0, 1 , 0 ]
    var edge_edges = [ 3 , 1, 0 , 2, 1 , 3, 2 , 0 ]
    var pre_edit = null
    if undoable:
        pre_edit = selector.editing.ply_mesh.begin_edit()
    selector.editing.ply_mesh.set_mesh(vertexes, vertex_edges, face_edges, edge_vertexes, edge_faces, edge_edges)
    if undoable:
        selector.editing.ply_mesh.commit_edit("Generate Plane", undo_redo, pre_edit)

const Extrude = preload("./resources/extrude.gd")
const Subdivide = preload("./resources/subdivide.gd")
const Loop = preload("./resources/loop.gd")

func _extrude():
    if not selector.editing or selector.mode != SelectionMode.FACE or selector.selection.size() == 0:
        return
    Extrude.faces(selector.editing.ply_mesh, selector.selection, undo_redo, 1)

func _subdivide_edge():
    if not selector.editing or selector.mode != SelectionMode.EDGE or selector.selection.size() != 1:
        return
    Subdivide.edge(selector.editing.ply_mesh, selector.selection[0], undo_redo)

func _select_face_loop(offset):
    if not selector.editing or selector.mode != SelectionMode.FACE or selector.selection.size() != 1:
        return
    var loop = Loop.get_face_loop(selector.editing.ply_mesh, selector.selection[0], offset)[0]
    selector.set_selection(loop)

func _cut_edge_loop():
    if not selector.editing or selector.mode != SelectionMode.EDGE or selector.selection.size() != 1:
        return
    Loop.edge_cut(selector.editing.ply_mesh, selector.selection[0], undo_redo)



"""
██╗   ██╗██╗███████╗██╗██████╗ ██╗██╗     ██╗████████╗██╗   ██╗
██║   ██║██║██╔════╝██║██╔══██╗██║██║     ██║╚══██╔══╝╚██╗ ██╔╝
██║   ██║██║███████╗██║██████╔╝██║██║     ██║   ██║    ╚████╔╝ 
╚██╗ ██╔╝██║╚════██║██║██╔══██╗██║██║     ██║   ██║     ╚██╔╝  
 ╚████╔╝ ██║███████║██║██████╔╝██║███████╗██║   ██║      ██║   
  ╚═══╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   
"""
func _on_selection_changed(mode, editing, selection):
    make_visible(editing && true)

func make_visible(vis):
    hotbar.set_visible(vis)
    if not hotbar.generate_cube.is_connected("pressed", self, "_generate_cube"):
        hotbar.generate_cube.connect("pressed", self, "_generate_cube")
        hotbar.generate_plane.connect("pressed", self, "_generate_plane")
        hotbar.face_extrude.connect("pressed", self, "_extrude")
        hotbar.edge_subdivide.connect("pressed", self, "_subdivide_edge")
        hotbar.edge_cut_loop.connect("pressed", self, "_cut_edge_loop")
        hotbar.face_select_loop_0.connect("pressed", self, "_select_face_loop", [0])
        hotbar.face_select_loop_1.connect("pressed", self, "_select_face_loop", [1])

"""
███████╗███████╗██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
██╔════╝██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
███████╗█████╗  ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
╚════██║██╔══╝  ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
███████║███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
╚══════╝╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
"""

func forward_spatial_gui_input(camera, event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            print(camera, ": ", event.position)
    return false
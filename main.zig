const io = @import("header.zig");

const Tree = struct {
    left: ?*Tree,
    right: ?*Tree,
    value: i32,
};

var tree_mem: [1 << 16]u8 = undefined;
var tree_idx: usize = 0;

fn createNode(val: i32) *Tree {
    const ptr = &tree_mem[tree_idx];
    tree_idx += @sizeOf(Tree);
    const node = @as(*Tree, @ptrCast(@alignCast(ptr)));
    node.* = .{
        .left = null,
        .right = null,
        .value = val,
    };
    return node;
}

fn preOrder(node: ?*Tree) void {
    if (node == null) return;
    io.printInt(node.?.value);
    io.printChar(' ');
    preOrder(node.?.left);
    preOrder(node.?.right);
}

fn inOrder(node: ?*Tree) void {
    if (node == null) return;
    inOrder(node.?.left);
    io.printInt(node.?.value);
    io.printChar(' ');
    inOrder(node.?.right);
}

fn postOrder(node: ?*Tree) void {
    if (node == null) return;
    postOrder(node.?.left);
    postOrder(node.?.right);
    io.printInt(node.?.value);
    io.printChar(' ');
}

pub fn main() void {
    io.init();

    const root = createNode(1);
    root.left = createNode(2);
    root.right = createNode(3);
    root.left.?.left = createNode(4);
    root.left.?.right = createNode(5);
    root.right.?.left = createNode(6);
    root.right.?.right = createNode(7);

    io.printStr("Preorder: ");
    preOrder(root);
    io.printChar('\n');

    io.printStr("Inorder: ");
    inOrder(root);
    io.printChar('\n');

    io.printStr("Postorder: ");
    postOrder(root);
    io.printChar('\n');
}
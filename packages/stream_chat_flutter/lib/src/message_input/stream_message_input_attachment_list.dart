import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/src/attachment/attachment.dart';
import 'package:stream_chat_flutter/src/misc/stream_svg_icon.dart';
import 'package:stream_chat_flutter/src/theme/stream_chat_theme.dart';
import 'package:stream_chat_flutter/src/utils/utils.dart';
import 'package:stream_chat_flutter/src/video/video_thumbnail_image.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

/// WidgetBuilder used to build the message input attachment list.
///
/// see more:
///   - [StreamMessageInputAttachmentList]
typedef AttachmentListBuilder = Widget Function(
  BuildContext context,
  List<Attachment> attachments,
  ValueSetter<Attachment>? onRemovePressed,
);

/// WidgetBuilder used to build the message input attachment item.
///
/// see more:
///  - [StreamMessageInputAttachmentList]
typedef AttachmentItemBuilder = Widget Function(
  BuildContext context,
  Attachment attachment,
  ValueSetter<Attachment>? onRemovePressed,
);

/// {@template stream_message_input_attachment_list}
/// Widget used to display the list of attachments added to the message input.
///
/// By default, it displays the list of file attachments and media attachments
/// separately.
///
/// You can customize the list of file attachments and media attachments using
/// [fileAttachmentListBuilder] and [mediaAttachmentListBuilder] respectively.
///
/// You can also customize the attachment item using [fileAttachmentBuilder] and
/// [mediaAttachmentBuilder] respectively.
///
/// You can override the default action of removing an attachment by providing
/// [onRemovePressed].
/// {@endtemplate}
class StreamMessageInputAttachmentList extends StatefulWidget {
  /// {@macro stream_message_input_attachment_list}
  const StreamMessageInputAttachmentList({
    super.key,
    required this.attachments,
    this.onRemovePressed,
    this.fileAttachmentBuilder,
    this.mediaAttachmentBuilder,
    this.fileAttachmentListBuilder,
    this.mediaAttachmentListBuilder,
  });

  /// List of attachments to display thumbnails for.
  ///
  /// Open graph should be filtered out.
  final Iterable<Attachment> attachments;

  /// Builder used to build the file attachment item.
  final AttachmentItemBuilder? fileAttachmentBuilder;

  /// Builder used to build the media attachment item.
  final AttachmentItemBuilder? mediaAttachmentBuilder;

  /// Builder used to build the file attachment list.
  final AttachmentListBuilder? fileAttachmentListBuilder;

  /// Builder used to build the media attachment list.
  final AttachmentListBuilder? mediaAttachmentListBuilder;

  /// Callback called when the remove button is pressed.
  final ValueSetter<Attachment>? onRemovePressed;

  @override
  State<StreamMessageInputAttachmentList> createState() =>
      _StreamMessageInputAttachmentListState();
}

class _StreamMessageInputAttachmentListState
    extends State<StreamMessageInputAttachmentList> {
  List<Attachment> fileAttachments = [];
  List<Attachment> mediaAttachments = [];

  void _updateAttachments() {
    // Clear the lists.
    fileAttachments.clear();
    mediaAttachments.clear();

    // Split the attachments into file and media attachments.
    for (final attachment in widget.attachments) {
      if (attachment.type == 'file') {
        fileAttachments.add(attachment);
      } else {
        mediaAttachments.add(attachment);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _updateAttachments();
  }

  @override
  void didUpdateWidget(covariant StreamMessageInputAttachmentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachments != widget.attachments) {
      _updateAttachments();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there are no attachments, return an empty box.
    if (fileAttachments.isEmpty && mediaAttachments.isEmpty) {
      return const SizedBox();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (mediaAttachments.isNotEmpty)
            Flexible(
              child: widget.mediaAttachmentListBuilder?.call(
                    context,
                    mediaAttachments,
                    widget.onRemovePressed,
                  ) ??
                  MessageInputMediaAttachments(
                    attachments: mediaAttachments,
                    attachmentBuilder: widget.mediaAttachmentBuilder,
                    onRemovePressed: widget.onRemovePressed,
                  ),
            ),
          if (fileAttachments.isNotEmpty)
            Flexible(
              child: widget.fileAttachmentListBuilder?.call(
                    context,
                    fileAttachments,
                    widget.onRemovePressed,
                  ) ??
                  MessageInputFileAttachments(
                    attachments: fileAttachments,
                    attachmentBuilder: widget.fileAttachmentBuilder,
                    onRemovePressed: widget.onRemovePressed,
                  ),
            ),
        ].insertBetween(
          Divider(
            height: 16,
            indent: 16,
            endIndent: 16,
            thickness: 1,
            color: StreamChatTheme.of(context).colorTheme.disabled,
          ),
        ),
      ),
    );
  }
}

/// Widget used to display the list of file type attachments added to the
/// message input.
class MessageInputFileAttachments extends StatelessWidget {
  /// Creates a new FileAttachments widget.
  const MessageInputFileAttachments({
    super.key,
    required this.attachments,
    this.attachmentBuilder,
    this.onRemovePressed,
  });

  /// List of file type attachments to display thumbnails for.
  final List<Attachment> attachments;

  /// Builder used to build the file type attachment item.
  final AttachmentItemBuilder? attachmentBuilder;

  /// Callback called when the remove button is pressed.
  final ValueSetter<Attachment>? onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: attachments.reversed.map<Widget>(
        (attachment) {
          // If a custom builder is provided, use it.
          final builder = attachmentBuilder;
          if (builder != null) {
            return builder(context, attachment, onRemovePressed);
          }

          // Otherwise, use the default builder.
          return ClipRRect(
            key: Key(attachment.id),
            borderRadius: BorderRadius.circular(10),
            child: StreamFileAttachment(
              message: Message(), // dummy message
              attachment: attachment,
              constraints: BoxConstraints.loose(Size(
                MediaQuery.sizeOf(context).width * 0.65,
                56,
              )),
              trailing: Padding(
                padding: const EdgeInsets.all(8),
                child: RemoveAttachmentButton(
                  onPressed: onRemovePressed != null
                      ? () => onRemovePressed!(attachment)
                      : null,
                ),
              ),
            ),
          );
        },
      ).insertBetween(const SizedBox(height: 8)),
    );
  }
}

/// Widget used to display the list of media type attachments added to the
/// message input.
class MessageInputMediaAttachments extends StatelessWidget {
  /// Creates a new MediaAttachments widget.
  const MessageInputMediaAttachments({
    super.key,
    required this.attachments,
    this.attachmentBuilder,
    this.onRemovePressed,
  });

  /// List of media type attachments to display thumbnails for.
  ///
  /// Only attachments of type `image`, `video` and `giphy` are supported. Shows
  /// a placeholder for other types of attachments.
  final List<Attachment> attachments;

  /// Builder used to build the media type attachment item.
  final AttachmentItemBuilder? attachmentBuilder;

  /// Callback called when the remove button is pressed.
  final ValueSetter<Attachment>? onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: attachments.map<Widget>(
          (attachment) {
            // If a custom builder is provided, use it.
            final builder = attachmentBuilder;
            if (builder != null) {
              return builder(context, attachment, onRemovePressed);
            }

            return ClipRRect(
              key: Key(attachment.id),
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1,
                    child: MessageInputMediaAttachmentThumbnail(
                      attachment: attachment,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: RemoveAttachmentButton(
                      onPressed: onRemovePressed != null
                          ? () => onRemovePressed!(attachment)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ).insertBetween(const SizedBox(width: 8)),
      ),
    );
  }
}

/// A widget that displays a thumbnail for a media attachment.
class MessageInputMediaAttachmentThumbnail extends StatelessWidget {
  /// Creates a new media attachment widget.
  const MessageInputMediaAttachmentThumbnail({
    super.key,
    required this.attachment,
  });

  /// The attachment to display.
  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    switch (attachment.type) {
      case 'image':
      case 'giphy':
        return attachment.file != null
            ? Image.memory(
                attachment.file!.bytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Image.asset(
                  'images/placeholder.png',
                  package: 'stream_chat_flutter',
                ),
              )
            : CachedNetworkImage(
                imageUrl: attachment.imageUrl ??
                    attachment.assetUrl ??
                    attachment.thumbUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, obj, trace) => Image.asset(
                  'images/placeholder.png',
                  package: 'stream_chat_flutter',
                ),
              );
      case 'video':
        return Stack(
          children: [
            StreamVideoThumbnailImage(
              video: attachment.file?.path ?? attachment.assetUrl,
            ),
            Positioned(
              left: 8,
              bottom: 10,
              child: StreamSvgIcon.videoCall(),
            ),
          ],
        );
      default:
        return const ColoredBox(
          color: Colors.black26,
          child: Icon(Icons.insert_drive_file),
        );
    }
  }
}

/// Material Button used for removing attachments.
class RemoveAttachmentButton extends StatelessWidget {
  /// Creates a new remove attachment button.
  const RemoveAttachmentButton({super.key, this.onPressed});

  /// Callback when the remove attachment button is pressed.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = StreamChatTheme.of(context);
    final colorTheme = theme.colorTheme;

    return SizedBox(
      width: 24,
      height: 24,
      child: RawMaterialButton(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        fillColor: colorTheme.textHighEmphasis.withOpacity(0.5),
        child: StreamSvgIcon.close(
          size: 24,
          color: colorTheme.barsBg,
        ),
      ),
    );
  }
}

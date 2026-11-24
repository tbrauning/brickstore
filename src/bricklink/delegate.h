// Copyright (C) 2004-2026 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QStyledItemDelegate>

#include "bricklink/global.h"
#include "desktop/betteritemdelegate.h"


namespace BrickLink {

class ItemDelegate : public BetterItemDelegate
{
    Q_OBJECT
public:
    ItemDelegate(Options options = None, QAbstractItemView *parent = nullptr);

    void paint(QPainter *painter, const QStyleOptionViewItem &option,
               const QModelIndex &index) const override;

    // If BrickLink has no image for an item (e.g. it cannot be reached), show a rendering from
    // the LDraw library instead. This is opt-in, because rendering is not free.
    bool useFallbackImages() const { return m_useFallbackImages; }
    void setUseFallbackImages(bool b) { m_useFallbackImages = b; }

public slots:
    bool helpEvent(QHelpEvent *event, QAbstractItemView *view, const QStyleOptionViewItem &option,
                   const QModelIndex &index) override;

private:
    bool m_useFallbackImages = false;
};


class ItemThumbsDelegate : public BrickLink::ItemDelegate
{
    Q_OBJECT
public:
    ItemThumbsDelegate(double initialZoom, QAbstractItemView *view = nullptr);

    QSize sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const override;

    double zoomFactor() const;
    void setZoomFactor(double zoom);

signals:
    void zoomFactorChanged(double newZoom);

private:
    double m_zoom;
    QAbstractItemView *m_view;
};


class ToolTip : public QObject
{
    Q_OBJECT
public:
    static ToolTip *inst();

    bool show(const Item *item, const Color *color, const Category *category,
              const QPoint &globalPos, QWidget *parent);

private slots:
    void pictureUpdated(const BrickLink::PictureRef &pic);

private:
    QString createItemToolTip(const Item *item, const Picture *pic) const;
    QString createColorToolTip(const Color *color) const;
    QString createCategoryToolTip(const Category *category) const;

    static QString yearSpan(int from, int to);

    static ToolTip *s_inst;
    PictureRef m_tooltip_pic;
};

} // namespace BrickLink

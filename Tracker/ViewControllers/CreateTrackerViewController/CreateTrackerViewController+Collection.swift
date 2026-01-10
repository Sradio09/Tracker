import UIKit

extension CreateTrackerViewController: UICollectionViewDelegate {

    // MARK: - Layout

    func makeCollectionLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let side: CGFloat = 52
            let columns = 6

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(side),
                heightDimension: .absolute(side)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(side)
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(8)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 24, trailing: 0)

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(34)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
    }

    // MARK: - DataSource

    func setupCollectionDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: selectionCollectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }

            switch item {
            case .emoji(let value):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: EmojiCell.reuseId,
                    for: indexPath
                )
                if let emojiCell = cell as? EmojiCell {
                    emojiCell.configure(emoji: value)
                }
                return cell

            case .color(let color):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ColorCell.reuseId,
                    for: indexPath
                )
                if let colorCell = cell as? ColorCell {
                    colorCell.configure(color: color)
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }

            let reusable = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SectionHeaderView.reuseId,
                for: indexPath
            )

            guard let header = reusable as? SectionHeaderView else { return reusable }

            if let section = Section(rawValue: indexPath.section) {
                header.configure(title: section.title)
            } else {
                header.configure(title: "")
            }

            return header
        }
    }

    func applyCollectionSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(emojis.map { .emoji($0) }, toSection: .emoji)
        snapshot.appendItems(colors.map { .color($0) }, toSection: .color)

        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.updateSelectionCollectionHeight()
            self?.view.layoutIfNeeded()
            self?.applyInitialSelectionIfNeeded()
        }
    }

    // MARK: - Selection

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              let section = Section(rawValue: indexPath.section) else { return }

        switch (section, item) {
        case (.emoji, .emoji(let value)):
            if let prev = selectedEmojiIndexPath, prev != indexPath {
                collectionView.deselectItem(at: prev, animated: false)
            }
            selectedEmojiIndexPath = indexPath
            selectedEmoji = value

        case (.color, .color(let color)):
            if let prev = selectedColorIndexPath, prev != indexPath {
                collectionView.deselectItem(at: prev, animated: false)
            }
            selectedColorIndexPath = indexPath
            selectedColor = color

        default:
            break
        }

        validate()
    }

    // MARK: - Height

    func updateSelectionCollectionHeight() {
        selectionCollectionView.layoutIfNeeded()
        let height = selectionCollectionView.collectionViewLayout.collectionViewContentSize.height
        guard height > 1 else { return }

        if selectionCollectionHeightConstraint?.constant != height {
            selectionCollectionHeightConstraint?.constant = height
        }
    }
}
